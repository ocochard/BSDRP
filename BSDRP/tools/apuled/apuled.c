/*-
 * Copyright (c) 2014-2017 Larry Baird
 * All rights reserved.
 *
 * Feedback provided by Ermal Luci.
 *
 * Used information from daduke's linux driver (https://daduke.org/linux/apu2)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */


#include <sys/param.h>
#include <sys/conf.h>
#include <sys/bus.h>
#include <sys/priv.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/proc.h>
#include <dev/pci/pcireg.h>
#include <dev/pci/pcivar.h>
#include <sys/kernel.h>
#include <sys/systm.h>
#include <sys/module.h>
#include <sys/rman.h>
#include <x86/bus.h>
#include <isa/isavar.h>
#include <dev/led/led.h>

#if __FreeBSD_version < 1100000
#   define kern_getenv(a) getenv(a)
#endif // __FreeBSD_version < 1100000

/*
 * Basic idea is to create two MMIO memory resources. One for LEds and
 * one for switch on front of APU.
 */

/* See dev/amdsbwd/amd_chipset.h for magic numbers for southbridges */

/* SB7xx RRG 2.3.3.1.1. */
#define AMDSB_PMIO_INDEX                0xcd6
#define AMDSB_PMIO_DATA                 (PMIO_INDEX + 1)
#define AMDSB_PMIO_WIDTH                2

#define AMDSB_SMBUS_DEVID               0x43851002
#define AMDFCH_SMBUS_DEVID              0x780b1022

/* SB8xx RRG 2.3.7. */
#define AMDSB8_MMIO_BASE_ADDR_FIND	0x24

/* Here are some magic numbers from APU1 BIOS. */
#define GPIO_OFFSET			0x100
#define GPIO_187      			187       // APU1 MODESW
#define GPIO_188      			188       // APU1 Unknown ??
#define GPIO_189      			189       // APU1 LED1#
#define GPIO_190      			190       // APU1 LED2#
#define GPIO_191      			191       // APU1 LED3#

#define LED_ON           		0x08
#define LED_OFF          		0xC8

/* Here are some magic numbers for APU2. */
#define AMDFCH41_MMIO_ADDR      	0xfed80000u
#define FCH_GPIO_OFFSET           	0x1500
#define FCH_GPIO_BASE           	(AMDFCH41_MMIO_ADDR + FCH_GPIO_OFFSET)
#define FCH_GPIO_SIZE           	0x300
#define APU2_GPIO_BIT_WRITE          	22
#define APU2_GPIO_BIT_READ           	16
#define GPIO_68      			68       // APU2 LED1#
#define GPIO_69      			69       // APU2 LED2#
#define GPIO_70      			70       // APU2 LED3#
#define GPIO_89      			89       // APU2 MODESW

struct apuled {
	struct resource *res;
	bus_size_t 	offset;
	struct cdev    	*led;
	int		model;
};

struct apuled_softc {
	int		sc_model;
        int             sc_rid_type;
	struct resource *sc_res_led;
        int             sc_rid_led;
	struct apuled   sc_led[3];
	struct resource *sc_res_modesw;
        int             sc_rid_modesw;
	struct cdev	*sc_sw;
};

/*
 * Mode switch methods.
 */
static int      modesw_open(struct cdev *dev, int flags, int fmt,
                        struct thread *td);
static int      modesw_close(struct cdev *dev, int flags, int fmt,
                        struct thread *td);
static int      modesw_read(struct cdev *dev, struct uio *uio, int ioflag);

static struct cdevsw msw_cdev = {
	.d_version =    D_VERSION,
	.d_open =       modesw_open,
	.d_read	=	modesw_read,
	.d_close =      modesw_close,
	.d_name =       "modesw",
};

/*
 * Device methods.
 */
static int	apuled_probe(device_t dev);
static int	apuled_attach(device_t dev);
static int	apuled_detach(device_t dev);
static void	apuled_identify(driver_t *driver, device_t parent);

static device_method_t apuled_methods[] = {
	/* Device interface */
	DEVMETHOD(device_probe,		apuled_probe),
	DEVMETHOD(device_attach,	apuled_attach),
	DEVMETHOD(device_detach,	apuled_detach),
	DEVMETHOD(device_identify,	apuled_identify),

	DEVMETHOD_END
};

static driver_t apuled_driver = {
	"apuled",
	apuled_methods,
	sizeof(struct apuled_softc),
};

static devclass_t apuled_devclass;
DRIVER_MODULE(apuled, isa, apuled_driver, apuled_devclass, NULL, NULL);

static int
hw_is_apu( void )
{
	int apu = 0;
	char *maker;
	char *product;

	maker = kern_getenv("smbios.system.maker");
	if (maker != NULL) {
		if ( 0 == strcasecmp( "PC Engines", maker ) ) {
			product = kern_getenv("smbios.system.product");
			if (product != NULL) {
				if ( 0 == strcasecmp( "APU", product ) )
					apu = 1;
				else if ( 0 == strcasecmp( "apu2", product ) )
					apu = 2;

				freeenv(product);
			}
		}

		freeenv(maker);
	}

	return (apu);
}

static void
apu_led_callback(void *ptr, int onoff)
{
	struct apuled *led = (struct apuled *)ptr;

	switch(led->model) {
	case 1: {
		u_int8_t value;

		value = bus_read_1(led->res, led->offset);

		if ( onoff )
			value = LED_ON;
		else
			value = LED_OFF;

		bus_write_1(led->res, led->offset, value);
		break;
	}

	case 2: {
		u_int32_t value;
		u_int32_t active_bit = 1 << APU2_GPIO_BIT_WRITE;

		value = bus_read_4(led->res, led->offset);

		if ( onoff )
			value &= ~active_bit;
		else
			value |= active_bit;

		bus_write_4(led->res, led->offset, value);
		break;
	}

	default:
		break;
	}
}

/* Check to see if this might be an APU board? Nothing too expensive */
static void
apuled_identify(driver_t *driver, device_t parent)
{
	device_t	child;
	device_t	smb;
	int id;

	if (resource_disabled("apuled", 0))
		return;

	if (device_find_child(parent, "apuled", -1) != NULL) 
		return;

	/* Do was have expected south bridge chipset? */
	smb = pci_find_bsf(0, 20, 0);
	if (smb == NULL)
		return;

	id=pci_get_devid(smb);

	switch(hw_is_apu()) {
	case 1:
		if ( id != AMDSB_SMBUS_DEVID )
			return;
		break;
	case 2:
		if ( id != AMDFCH_SMBUS_DEVID )
			return;
		break;

	default:
		return;
	}

	/* Everything looks good, enable probe */
	child = BUS_ADD_CHILD(parent, ISA_ORDER_SPECULATIVE, "apuled", -1);
	if ( child == NULL )
		device_printf(parent, "apuled: bus add child failed\n");
}

static int 
apuled_probe_apu1(device_t dev, struct apuled_softc *sc)
{
	struct resource         *res;
	int			rc;
	uint32_t		gpio_mmio_base;
	int			rid;
	int			i;

	/* Find the ACPImmioAddr base address */
	rc = bus_set_resource(dev, SYS_RES_IOPORT, 0, AMDSB_PMIO_INDEX,
	    AMDSB_PMIO_WIDTH);
	if (rc != 0) {
		device_printf(dev, "bus_set_resource for MMIO failed\n");
		return (ENXIO);
	}

	rid = 0;
	res = bus_alloc_resource(dev, SYS_RES_IOPORT, &rid, 0ul, ~0ul,
	    AMDSB_PMIO_WIDTH, RF_ACTIVE | RF_SHAREABLE);

	if (res == NULL) {
		device_printf(dev, "bus_alloc_resource for MMIO failed.\n");
		return (ENXIO);
	}

	/* Find base address of memory mapped WDT registers. */
	/* This will probable be 0xfed80000 */
	for (gpio_mmio_base = 0, i = 0; i < 4; i++) {
		gpio_mmio_base <<= 8;
		bus_write_1(res, 0, AMDSB8_MMIO_BASE_ADDR_FIND + 3 - i);
		gpio_mmio_base |= bus_read_1(res, 1);
	}
	gpio_mmio_base &= ~0x07u;

	if ( bootverbose )
		device_printf(dev, "MMIO base adddress 0x%x\n", gpio_mmio_base);

	bus_release_resource(dev, SYS_RES_IOPORT, rid, res);
	bus_delete_resource(dev, SYS_RES_IOPORT, rid);

	/* Set memory resource for LEDs. */
	rc = bus_set_resource(dev, SYS_RES_MEMORY, 0,
	    gpio_mmio_base + GPIO_OFFSET + GPIO_189,
	    (GPIO_191 - GPIO_189) + 1);
	if (rc != 0) {
		device_printf(dev, "bus_set_resource for LEDs failed\n");
		return (ENXIO);
	}

	/* Set memory resource for modesw. */
	rc = bus_set_resource(dev, SYS_RES_MEMORY, 1,
	    gpio_mmio_base + GPIO_OFFSET + GPIO_187, 1);
	if (rc != 0) {
		device_printf(dev, "bus_set_resource for modesw failed\n");
		return (ENXIO);
	}

	return (0);
}

static int 
apuled_probe_apu2(device_t dev, struct apuled_softc *sc)
{
	int			rc;

	/* Set memory resource for LEDs. */
	rc = bus_set_resource(dev, SYS_RES_MEMORY, 0,
	    FCH_GPIO_BASE + (GPIO_68 * sizeof(uint32_t)),
	    ((GPIO_70 - GPIO_68) + 1) * sizeof(uint32_t) );
	if (rc != 0) {
		device_printf(dev, "bus_set_resource for LEDs failed\n");
		return (ENXIO);
	}

	/* Set memory resource for modesw. */
	rc = bus_set_resource(dev, SYS_RES_MEMORY, 1,
	    FCH_GPIO_BASE + (GPIO_89 * sizeof(uint32_t)),
	    sizeof(uint32_t) );
	if (rc != 0) {
		device_printf(dev, "bus_set_resource for modesw failed\n");
		return (ENXIO);
	}

	return (0);
}


static int
apuled_probe(device_t dev)
{
	int			error;
	char			buf[100];
	struct apuled_softc 	*sc = device_get_softc(dev);

	/* Make sure we do not claim some ISA PNP device. */
	if (isa_get_logicalid(dev) != 0)
		return (ENXIO);

	sc->sc_model = hw_is_apu();
	if ( sc->sc_model == 0 )
		return (ENXIO);

	snprintf(buf, sizeof(buf), "APU%d", sc->sc_model);
	device_set_desc_copy(dev, buf );

	switch( sc->sc_model ) {
	case 1:
		error = apuled_probe_apu1( dev, sc );
		if (error)
		    return error;
		break;

	case 2:
		error = apuled_probe_apu2( dev, sc );
		if (error)
		    return error;
		break;

	default:	/* Should never reach here. */
		device_printf(dev, "Unexpected APU model\n" );
		return (ENXIO);
		break;
	}

	return (0);
}


static int
apuled_attach(device_t dev)
{
	struct apuled_softc *sc = device_get_softc(dev);
	int i;

	sc->sc_rid_type = SYS_RES_MEMORY;
	sc->sc_res_led = NULL;
	sc->sc_rid_led = 0;
	sc->sc_res_modesw = NULL;
	sc->sc_rid_modesw = 1;

	/* Allocate LEDs memory region */
	sc->sc_res_led = bus_alloc_resource_any( dev, sc->sc_rid_type,
	    &sc->sc_rid_led, RF_ACTIVE | RF_SHAREABLE);
	if ( sc->sc_res_led == NULL ) {
		device_printf( dev, "Unable to allocate LED memory region\n" );
		return (ENXIO);
	}

	/* Allocate modesw memory region */
	sc->sc_res_modesw = bus_alloc_resource_any( dev, sc->sc_rid_type,
	    &sc->sc_rid_modesw, RF_ACTIVE | RF_SHAREABLE);
	if ( sc->sc_res_modesw == NULL ) {
		bus_release_resource(dev, sc->sc_rid_type, sc->sc_rid_led,
		    sc->sc_res_led);
		sc->sc_res_led = NULL;
		device_printf( dev,
		    "Unable to allocate modesw memory region\n" );
		return (ENXIO);
	}

	sc->sc_sw = make_dev(&msw_cdev, 0, UID_ROOT, GID_WHEEL, 0440, "modesw");
	sc->sc_sw->si_drv1 = sc;

	for ( i = 0; i < 3; i++ ) {
		char name[30];

		snprintf( name, sizeof(name), "led%d", i + 1 );

		sc->sc_led[ i ].res = sc->sc_res_led;
		sc->sc_led[ i ].model = sc->sc_model;

		if ( sc->sc_model == 1 )
		    sc->sc_led[ i ].offset = i;
		else
		    sc->sc_led[ i ].offset = i * sizeof(uint32_t);

		sc->sc_led[ i ].led = led_create(apu_led_callback,
		    &sc->sc_led[ i ], name);

		if ( sc->sc_led[ i ].led == NULL ) {
			device_printf( dev, "%s creation failed\n", name );

		} else if ( i == 0 ) {
			/* Make sure power LED stays on by default */
			apu_led_callback(&sc->sc_led[ i ], TRUE);
		}
	}

	return (0);
}

int
apuled_detach(device_t dev)
{
	struct apuled_softc *sc = device_get_softc(dev);
	int i;

	for ( i = 0; i < 3; i++ )
		if ( sc->sc_led[ i ].led != NULL ) {
			/* Restore LEDs to stating state */
			if ( i == 0 )
				apu_led_callback(&sc->sc_led[ i ], TRUE);
			else
				apu_led_callback(&sc->sc_led[ i ], FALSE);

			led_destroy(sc->sc_led[ i ].led);
		}

	if ( sc->sc_res_led != NULL ) {
		bus_release_resource(dev, sc->sc_rid_type, sc->sc_rid_led,
		    sc->sc_res_led);
		bus_delete_resource(dev, sc->sc_rid_type, sc->sc_rid_led );
	}

	if ( sc->sc_res_modesw != NULL ) {
		bus_release_resource(dev, sc->sc_rid_type, sc->sc_rid_modesw,
		    sc->sc_res_modesw);
		bus_delete_resource(dev, sc->sc_rid_type, sc->sc_rid_modesw );
	}

	if ( sc->sc_sw != NULL )
	    destroy_dev(sc->sc_sw);

	return (0);
}

static int
modesw_open(struct cdev *dev __unused, int flags __unused, int fmt __unused,
    struct thread *td)
{
	int error;

	error = priv_check(td, PRIV_IO);
	if (error != 0)
		return (error);
	error = securelevel_gt(td->td_ucred, 0);

	return (error);
}

static int
modesw_read(struct cdev *dev, struct uio *uio, int ioflag) {
	struct apuled_softc *sc = dev->si_drv1;
        char ch = '0';
        int error;

	switch(sc->sc_model) {
	case 1: {
		uint8_t value;

		/* Is mode switch pressed? */
		value = bus_read_1(sc->sc_res_modesw, 0 );

		if (value == 0x28 )
			ch = '1';
		break;
	}

	case 2: {
		uint32_t value;

		/* Is mode switch pressed? */
		value = bus_read_4(sc->sc_res_modesw, 0 );

		if ( ! ((value >> APU2_GPIO_BIT_READ) & 1) )
			ch = '1';
		break;
	}

	default:
		break;
	}

	error = uiomove(&ch, sizeof(ch), uio);

	return (error);
}

static int
modesw_close(struct cdev *dev __unused, int flags __unused, int fmt __unused,
    struct thread *td __unused)
{
	return (0);
}
