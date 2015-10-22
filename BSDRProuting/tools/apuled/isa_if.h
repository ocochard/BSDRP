/*
 * This file is produced automatically.
 * Do not modify anything in here by hand.
 *
 * Created from source file
 *   /usr/src/sys/isa/isa_if.m
 * with
 *   makeobjops.awk
 *
 * See the source file for legal information
 */


#ifndef _isa_if_h_
#define _isa_if_h_

/** @brief Unique descriptor for the ISA_ADD_CONFIG() method */
extern struct kobjop_desc isa_add_config_desc;
/** @brief A function implementing the ISA_ADD_CONFIG() method */
typedef int isa_add_config_t(device_t dev, device_t child, int priority,
                             struct isa_config *config);

static __inline int ISA_ADD_CONFIG(device_t dev, device_t child, int priority,
                                   struct isa_config *config)
{
	kobjop_t _m;
	KOBJOPLOOKUP(((kobj_t)dev)->ops,isa_add_config);
	return ((isa_add_config_t *) _m)(dev, child, priority, config);
}

/** @brief Unique descriptor for the ISA_SET_CONFIG_CALLBACK() method */
extern struct kobjop_desc isa_set_config_callback_desc;
/** @brief A function implementing the ISA_SET_CONFIG_CALLBACK() method */
typedef void isa_set_config_callback_t(device_t dev, device_t child,
                                       isa_config_cb *fn, void *arg);

static __inline void ISA_SET_CONFIG_CALLBACK(device_t dev, device_t child,
                                             isa_config_cb *fn, void *arg)
{
	kobjop_t _m;
	KOBJOPLOOKUP(((kobj_t)dev)->ops,isa_set_config_callback);
	((isa_set_config_callback_t *) _m)(dev, child, fn, arg);
}

/** @brief Unique descriptor for the ISA_PNP_PROBE() method */
extern struct kobjop_desc isa_pnp_probe_desc;
/** @brief A function implementing the ISA_PNP_PROBE() method */
typedef int isa_pnp_probe_t(device_t dev, device_t child,
                            struct isa_pnp_id *ids);

static __inline int ISA_PNP_PROBE(device_t dev, device_t child,
                                  struct isa_pnp_id *ids)
{
	kobjop_t _m;
	KOBJOPLOOKUP(((kobj_t)dev)->ops,isa_pnp_probe);
	return ((isa_pnp_probe_t *) _m)(dev, child, ids);
}

#endif /* _isa_if_h_ */
