/*-
 * Copyright (c) 2014 Larry Baird
 * All rights reserved.
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

/* SB7xx RRG 2.3.3.1.1. */
#define AMDSB_PMIO_INDEX                0xcd6
#define AMDSB_PMIO_DATA                 (PMIO_INDEX + 1)
#define AMDSB_PMIO_WIDTH                2

#define AMDSB_SMBUS_DEVID               0x43851002

/* SB8xx RRG 2.3.3. */
#define AMDSB8_PM_WDT_EN                0x24

/* Here are some magic numbers from APU BIOS. */
#define GPIO_OFFSET			0x100
#define GPIO_187      			187       // MODESW
#define GPIO_188      			188       // Unknown ??
#define GPIO_189      			189       // LED1#
#define GPIO_190      			190       // LED2#
#define GPIO_191      			191       // LED3#

#define LED_ON           		0x08
#define LED_OFF          		0xC8

struct apuled {
	struct resource *res;
	bus_size_t 	offset;
	struct cdev    	*led;
};

struct apuled_softc {
        int             sc_rid;
        int             sc_type;
	struct resource *sc_res;
	struct apuled   sc_led[3];
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

static struct cdevsw modesw_cdev = {
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
		if ( 0 == strcmp( "PC Engines", maker ) ) {
			product = kern_getenv("smbios.system.product");
			if (product != NULL) {
				if ( 0 == strcmp( "APU", product ) )
					apu = 1;

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
	u_int8_t value;

	value = bus_read_1(led->res, led->offset);

	if ( onoff )
		value = LED_ON;
	else
		value = LED_OFF;

	bus_write_1(led->res, led->offset, value);
}

static void
apuled_identify(driver_t *driver, device_t parent)
{
	device_t	child;
	device_t	smb;

	if (resource_disabled("apuled", 0))
		return;

	if (device_find_child(parent, "apuled", -1) != NULL)
		return;

	/* Do was have expected south bridge? */
	smb = pci_find_bsf(0, 20, 0);
	if (smb == NULL)
		return;

	if (pci_get_devid(smb) != AMDSB_SMBUS_DEVID)
		return;

	if ( hw_is_apu() ) {
		child = BUS_ADD_CHILD(parent, ISA_ORDER_SPECULATIVE, "apuled", -1);
		if ( child == NULL )
			device_printf(parent, "apuled: bus add child failed\n");
	}
}

static int
apuled_probe(device_t dev)
{
	struct resource         *res;
	int			rc;
	uint32_t		gpio_mmio_base;
	int			i;
	int			rid;

	/* Make sure we do not claim some ISA PNP device. */
	if (isa_get_logicalid(dev) != 0)
		return (ENXIO);

	if ( ! hw_is_apu() )
		return (ENXIO);

	/* Find the ACPImmioAddr base address */
	rc = bus_set_resource(dev, SYS_RES_IOPORT, 0, AMDSB_PMIO_INDEX,
	    AMDSB_PMIO_WIDTH);
	if (rc != 0) {
		device_printf(dev, "bus_set_resource for find address failed\n");
		return (ENXIO);
	}

	rid = 0;
	res = bus_alloc_resource(dev, SYS_RES_IOPORT, &rid, 0ul, ~0ul,
	    AMDSB_PMIO_WIDTH, RF_ACTIVE | RF_SHAREABLE);
	if (res == NULL) {
		device_printf(dev, "bus_alloc_resource for finding base address failed.\n");
		return (ENXIO);
	}

	/* Find base address of memory mapped WDT registers. */
	for (gpio_mmio_base = 0, i = 0; i < 4; i++) {
		gpio_mmio_base <<= 8;
		bus_write_1(res, 0, AMDSB8_PM_WDT_EN + 3 - i);
		gpio_mmio_base |= bus_read_1(res, 1);
	}
	gpio_mmio_base &= 0xFFFFF000;

	if ( bootverbose )
		device_printf(dev, "MMIO base adddress is 0x%x\n", gpio_mmio_base);

	bus_release_resource(dev, SYS_RES_IOPORT, rid, res);
	bus_delete_resource(dev, SYS_RES_IOPORT, rid);

	rc = bus_set_resource(dev, SYS_RES_MEMORY, 0,
	    gpio_mmio_base + GPIO_OFFSET + GPIO_187, GPIO_191 - GPIO_187);
	if (rc != 0) {
		device_printf(dev, "bus_set_resource for memory region failed\n");
		return (ENXIO);
	}

	return (0);
}


static int
apuled_attach(device_t dev)
{
	struct apuled_softc *sc = device_get_softc(dev);
	int i;

	sc->sc_rid = 0;
	sc->sc_type = SYS_RES_MEMORY;

	sc->sc_res = bus_alloc_resource_any( dev, sc->sc_type, &sc->sc_rid,
	    RF_ACTIVE | RF_SHAREABLE);

	if ( sc->sc_res == NULL ) {
		device_printf( dev, "Unable to allocate bus resource\n" );
		return (ENXIO);
	}

	sc->sc_sw = make_dev(&modesw_cdev, 0, UID_ROOT, GID_WHEEL, 0440, "modesw");
	sc->sc_sw->si_drv1 = sc;

	for ( i = 0; i < 3; i++ ) {
		char name[30];

		snprintf( name, sizeof(name), "led%d", i + 1 );

		sc->sc_led[ i ].res = sc->sc_res;
		sc->sc_led[ i ].offset = GPIO_189 - GPIO_187 + i;

		sc->sc_led[ i ].led = led_create(apu_led_callback,
		    &sc->sc_led[ i ], name);

		if ( sc->sc_led[ i ].led == NULL ) {
			device_printf( dev, "%s creation failed\n", name );

		/* Make sure power LED stays on by default */
		} else if ( i == 0 ) {
			apu_led_callback(&sc->sc_led[ i ], TRUE);
		}
	}

	device_printf( dev, "created\n" );

	return (0);
}

int
apuled_detach(device_t dev)
{
	struct apuled_softc *sc = device_get_softc(dev);
	int i;

	for ( i = 0; i < 3; i++ )
		if ( sc->sc_led[ i ].led != NULL ) {
			if ( i == 0 )
				apu_led_callback(&sc->sc_led[ i ], TRUE);
			else
				apu_led_callback(&sc->sc_led[ i ], FALSE);

			led_destroy(sc->sc_led[ i ].led);
		}

	if ( sc->sc_res != NULL ) {
		bus_release_resource(dev, sc->sc_type, sc->sc_rid, sc->sc_res);
		bus_delete_resource(dev, sc->sc_type, sc->sc_rid );
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
	if (error != 0)
		return (error);

	return (error);
}

static int
modesw_read(struct cdev *dev, struct uio *uio, int ioflag) {
	struct apuled_softc *sc = dev->si_drv1;
	uint8_t value;
        char ch;
        int error;

	/* Is mode switch pressed? */
	value = bus_read_1(sc->sc_res, GPIO_187 - GPIO_187 );
	if (value == 0x28 )
		ch = '1';
	else
		ch = '0';

	error = uiomove(&ch, sizeof(ch), uio);

	return (error);
}

static int
modesw_close(struct cdev *dev __unused, int flags __unused, int fmt __unused,
    struct thread *td __unused)
{
	return (0);
}

