/* PIM Sparse Mode multicast routing test
 * Purpose: There is a problem between FreeBSD 9.2 and 10.0 regarding pimd (PIM-SM daemon):
 * Need to write a small regression test for helping to spot the problem.
 * Code write as-a-book (without function for natural human ready)… just because it's a learning code.
 * sources used: man pages like multicast(4) and pim(4)
 * http://www.freebsd.org/doc/en/books/developers-handbook/sockets-essential-functions.html
 * http://www.cs.unc.edu/~jeffay/dirt/FAQ/comp249-001-F99/mcast-socket.html
*/

#include <stdio.h>
#include <stdlib.h> /* exit */
#include <string.h> /* memset, memcpy */
#include <unistd.h> /* close */
#include <sys/types.h>
#include <arpa/inet.h> /* ntoa */
//#include <netinet/in.h> /* sockaddr_in : no complains without????*/
#include <sys/socket.h>
#include <netinet/in.h> /* IPPROTO_*, ALLRTRS_GROUP, etc... */
#include <netinet/ip_mroute.h> /* vifctl, MRT_INIT, etc.. */
#include <netinet/pim.h> /* INADDR_ALLPIM_ROUTERS_GROUP */
#include <ifaddrs.h> /* getifaddrs, Note: <net/if.h> must be include before this */

int main(void)
{
	/* Concept:
	 * 1. Create an IGMP RAW socket
	 * 2. Enable multicast routing using the IGMP RAW socket
	 *    This action update some filters for receiving ALLRTRS_GROUP (224.0.0.2) :
	 *      we can see incoming packet with a tcpdump -p after
	 *      but ifmcstat didn't display ALLRTRS_GROUP: Need to manually IP_ADD_MEMBERSHIP
	 * 3. Enable PIM multicast routing still using IGMP RAW socket
	 *    Same problem regarding filter for ALLPIM_ROUTERS_GROUP (224.0.0.13) with ifmcstat
	 * 4. For each network interface:
	 *    - a corresponding multicast interface (vif) need to be added
	 *    - And they need to subscribe to ALLRTRS_GROUP, ALLRPTS_GROUP and ALLPIM_ROUTERS_GROUP
	*       with IP_ADD_MEMBERSHIP
	 *    to be added (vif)
	 * 5. Add a vif for the PIM-Register (PIM Sparse mode only)
	 * 6. Create a PIM RAW socket for sending/receiving PIM
	*/

	/* Example part from multicast(4)
	 * First, a multicast routing socket must be open.  That socket would be
	 * used to control the multicast forwarding in the kernel.  Note that most
	 *operations below require certain privilege (i.e., root privilege):
	*/

	int mrouter_s4;
	mrouter_s4 = socket(AF_INET, SOCK_RAW, IPPROTO_IGMP);
	if (mrouter_s4 < 0)
		perror("Failed to open IGMP RAW socket");

	/* After the multicast routing socket is open, it can be used to enable or
	disable multicast forwarding in the kernel: */

	int v = 1;        /* 1 to enable, or 0 to disable */
	if (setsockopt(mrouter_s4, IPPROTO_IP, MRT_INIT, (void *)&v, sizeof(v)) < 0) {
		perror("Failed to enable multicast routing: You need a multicast enabled kernel (options MROUTING)");
		exit(-1);
		/*NOTREACHED*/
	}

	/* And it can be used to enable or disable PIM processing in the
	kernel.*/
	v = 1;        /* 1 to enable, or 0 to disable */
	if (setsockopt(mrouter_s4, IPPROTO_IP, MRT_PIM, (void *)&v, sizeof(v)) < 0) {
		perror("Failde to enable PIM processing");
		exit(-1);
		/*NOTREACHED*/
	}

	/* For each network interface (e.g., physical or a virtual tunnel) that
	 * would be used for multicast forwarding, a corresponding multicast inter-
	 * face must be added to the kernel. In case of PIM-SM, the PIM-Register
	 * virtual interface must be added as well.
	*/

	int vif_index=0; /* counter for vif number */
	struct vifctl vc; /* system struct used for add/delete vif */
	/*
	 * Argument structure for MRT_ADD_VIF.
	 * (MRT_DEL_VIF takes a single vifi_t argument.)
	 *	struct vifctl {
	 *     vifi_t  vifc_vifi;              * the index of the vif to be added *
	 *     u_char  vifc_flags;             * VIFF_ flags defined below *
	 *     u_char  vifc_threshold;         * min ttl required to forward on vif *
	 *     u_int   vifc_rate_limit;        * max rate *
	 *     struct  in_addr vifc_lcl_addr;  * local interface address *
	 *     struct  in_addr vifc_rmt_addr;  * remote address (tunnels only) *
	 *	};
	*/

	memset(&vc, 0, sizeof(vc)); /* initialization (copy 0xlenght of vc into vc)*/

	/* We need to get all Network interface list and their IPv4 addresses first
	 * For this action, getifaddrs(3) is used and it need to use a struct ifaddrs
	*/

	struct ifaddrs *ifap,*ifa;

	/* struct ifaddrs {
	 *     struct ifaddrs  *ifa_next;
	 *     char            *ifa_name;
	 *     unsigned int     ifa_flags;
	 *     struct sockaddr *ifa_addr;
	 *     struct sockaddr *ifa_netmask;
	 *     struct sockaddr *ifa_dstaddr;
	 *     void            *ifa_data;
	 * };
	 * struct sockaddr {
	 *     unsigned char   sa_len;       * total length *
	 *     sa_family_t     sa_family;    * address family *
	 *     char            sa_data[14];  * actually longer; address value *
	 * };
	 * sockaddr_in can be mapped to sockaddr if AF_INET:
	 * struct sockaddr_in {
	 *	uint8_t		sin_len;
	 *	sa_family_t	sin_family;
	 *	in_port_t	sin_port;
	 *	struct	in_addr sin_addr;
	 *	char	sin_zero[8];
	 *};
	*/

	/* stores a reference to a linked list of the net interfaces */
	getifaddrs(&ifap);

	/* Display only AF_INET (IPv4) configured interfaces : */
	printf("Creating mcast vif for:\n");
	for (ifa = ifap; ifa != NULL; ifa = ifa->ifa_next) {
		if (ifa->ifa_addr->sa_family == AF_INET) {
			/* It's IPv4, then we can map ifa_addr to a sockaddr_in
			 * http://www.lemoda.net/freebsd/net-interfaces/index.html
			*/
			struct in_addr *addr_ptr = 0; /* pointer */
			char address[INET6_ADDRSTRLEN]; /* char table of max INET6 */
			addr_ptr = &((struct sockaddr_in *)ifa->ifa_addr)->sin_addr;
			/* inet(3) */
			inet_ntop(ifa->ifa_addr->sa_family,addr_ptr,address,sizeof(address));
			printf("- %s (%s)...",ifa->ifa_name, address);
			/* Assign all vifctl fields as appropriate */
			vc.vifc_vifi = vif_index; /* must be unique per vif */
			vc.vifc_flags = 0; /* set for pim_register only */
			vc.vifc_threshold = 1; /* minimum TTL to be forwarded to this vif */
			vc.vifc_rate_limit = 0; /* is no longer supported in FreeBSD */
			vc.vifc_lcl_addr = *addr_ptr; /* struct in_addr */
			if (setsockopt(mrouter_s4, IPPROTO_IP, MRT_ADD_VIF, (void *)&vc,
		sizeof(vc)) < 0)
				perror("Can't create vif!");
			else {
				printf("done: vif %d\n", vif_index);
				vif_index ++;
			}
			/* Now we need to subscribe to each mcast groups usefull for a router
			 *  with IP_ADD_MEMBERSHIP that use struct ip_mreq
			 *
			 * Argument structure for IP_ADD_MEMBERSHIP and IP_DROP_MEMBERSHIP.
			 * struct ip_mreq {
			 *        struct  in_addr imr_multiaddr;  * IP multicast address of group *
			 *        struct  in_addr imr_interface;  * local IP address of interface *
			 *};
			*/

			struct ip_mreq mreq;
			mreq.imr_multiaddr.s_addr =  htonl(INADDR_ALLRTRS_GROUP);
			mreq.imr_interface = vc.vifc_lcl_addr;
			printf("   Subscribing to %s...",inet_ntoa(mreq.imr_multiaddr));
		    if (setsockopt(mrouter_s4, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq,sizeof(mreq)) < 0)
				perror("Failed to add membership ALLRTRS_GROUP");
			else printf("done\n");
			mreq.imr_multiaddr.s_addr =  htonl(INADDR_ALLPIM_ROUTERS_GROUP);
			printf("   Subscribing to %s...",inet_ntoa(mreq.imr_multiaddr));
		    if (setsockopt(mrouter_s4, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq,sizeof(mreq)) < 0)
				perror("Failed to add membership ALLPIM_ROUTERS_GROUP");
			else printf("done\n");
			mreq.imr_multiaddr.s_addr =  htonl(INADDR_ALLRPTS_GROUP);
			printf("   Subscribing to %s...",inet_ntoa(mreq.imr_multiaddr));
		    if (setsockopt(mrouter_s4, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq,sizeof(mreq)) < 0)
				perror("Failed to add membership ALLRPTS_GROUP");
			else printf("done\n");
		}
	}

	/* We still need to create a vif for PIM-register virtual interface
	 * But what IP to use (kept the last one used)????
	*/
	//printf("Creating PIM-register vif using %s...", address);
	printf("Creating PIM-register vif...");
	vc.vifc_vifi = vif_index; /* must be unique per vif */
	vc.vifc_flags = VIFF_REGISTER; /* set for pim_register only */
	vc.vifc_threshold = 1; /* minimum TTL to be forwarded to this vif */
	vc.vifc_rate_limit = 0; /* is no longer supported in FreeBSD */
	/* vc.vifc_lcl_addr = *addr_ptr; */
	if (setsockopt(mrouter_s4, IPPROTO_IP, MRT_ADD_VIF, (void *)&vc,
	sizeof(vc)) < 0)
		perror("Can't create vif!");
	else printf("done (vif %d).\n", vif_index);
	//vif_index ++;

	/* We don't need ifap anymore */
	freeifaddrs(ifap);

	/* Now that PIM processing is enabled, we need to open a new socket for PIM */

	/* IPv4 */
	int pim_s4;
	pim_s4 = socket(AF_INET, SOCK_RAW, IPPROTO_PIM);
	if (pim_s4 < 0) perror("Failed to create PIM RAW socket");

	/* We need to bind the previous socket created before read on them */
	struct sockaddr_in igmp_sockaddr_in, pim_sockaddr_in;
	memset(&igmp_sockaddr_in, 0, sizeof(igmp_sockaddr_in));
	memset(&pim_sockaddr_in, 0, sizeof(pim_sockaddr_in));

	igmp_sockaddr_in.sin_family = AF_INET;
    //igmp_sockaddr_in.sin_addr.s_addr = htonl(INADDR_ALLRTRS_GROUP);
    //igmp_sockaddr_in.sin_port = htons(DEFAULT_PORT);
    //igmp_sockaddr_in.sin_len = sizeof(igmp_sockaddr_in);

	if (bind(mrouter_s4, (struct sockaddr *)&igmp_sockaddr_in, sizeof(igmp_sockaddr_in)) < 0) {
		perror("Could not bind to IGMP socket");
		exit (-1);
	}

	pim_sockaddr_in.sin_family = AF_INET;
	//pim_sockaddr_in.sin_addr.s_addr = htonl(INADDR_ALLPIM_ROUTERS_GROUP);
	if (bind(pim_s4, (struct sockaddr *)&pim_sockaddr_in, sizeof(pim_sockaddr_in)) < 0) {
		perror("Could not bind to PIM socket");
		exit (-1);
	}


	/* Loop that wait for PIM packet */

	/* Need to check: https://stackoverflow.com/questions/822964/linux-socket-programming-debug */
	/* We will use recvfrom:
	 * recvfrom(int s, void * restrict buf, size_t len, int flags,
	 * struct sockaddr * restrict from, socklen_t * restrict fromlen);
	*/
	int saddr_size, data_size;
	struct sockaddr saddr;
	saddr_size = sizeof saddr;
	unsigned char *buffer = (unsigned char *)malloc(65536); /* big size */

	printf("Waiting for receiving packet on the IGMP RAW socket...\n");
	while(1)
    {
		/* Last parameter of recvfrom is a socklen_t *
		 * need to convert the pointer to saddr_size with (socklen_t*)&
		 */
        data_size = recvfrom(mrouter_s4 , buffer , 65536 , 0 , &saddr , (socklen_t*)&saddr_size);
        if(data_size <0 ) printf("Recvfrom error , failed to get packets\n");
		else printf("get a packet!");
    }

	/* End: Need to cleanup */
	/* Delete Multicast vif */

	for (vifi_t vifi = 0 ; vifi <= vif_index; ++vifi) {
		/* TO DO: Unregister them before */
		printf("Deleting vif %d...",vifi);
		if (setsockopt(mrouter_s4, IPPROTO_IP, MRT_DEL_VIF, (void *)&vifi,
		sizeof(vifi)) < 0)
			perror("Can't delete vif!");
		else printf("done\n");
	}

	/* Need to disable mcast routing ???? */

	v = 0;        /* 1 to enable, or 0 to disable */
	if (setsockopt(mrouter_s4, IPPROTO_IP, MRT_PIM, (void *)&v, sizeof(v)) < 0)
		perror("Can't disable PIM processing");

	v = 0;        /* 1 to enable, or 0 to disable */
	if (setsockopt(mrouter_s4, IPPROTO_IP, MRT_INIT, (void *)&v, sizeof(v)) < 0)
		perror("Can't disable multicast routing");

	/* Closing socket */
	if (close(pim_s4) < 0) perror("close");
	if (close(mrouter_s4)< 0) perror("close");

}
