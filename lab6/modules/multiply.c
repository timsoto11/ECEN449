#include <linux/module.h> /* Needed by all modules */
#include <linux/kernel.h> /* Needed for KERN_* and printk */
#include <linux/init.h> /* Needed for __init and __exit macros */
#include <asm/io.h> /* Needed for IO reads and writes */

#include "xparameters.h" /* Needed for physical address of multiplier */

/*from xparameters.h*/
#define PHY_ADDR XPAR_MULTIPLY_0_BASEADDR //physical address of multiplier
/*size of physical address range for multiple */
#define MEMSIZE XPAR_MULTIPLY_0_HIGHADDR - XPAR_MULTIPLY_0_BASEADDR+1

void* virt_addr; //virtual address pointing to multiplier

/* This function is run upon module load. This is where you setup data structures and reserve resources used by the module. */

static int __init my_init(void) {
	/* Linux kernel's version of printf */
	printk(KERN_INFO "Mapping virtual address...\n");
	
	/*map virtual address to multiplier physical address*/
	//use ioremap
	virt_addr = ioremap(PHY_ADDR, MEMSIZE);
	printk("Physical Address: %x\n", PHY_ADDR); //Print physical address
	printk("Virtual Address: %x\n", virt_addr); //Print virtual address

	/*write 7 to register 0 */
	printk(KERN_INFO "Writing a 7 to register 0\n");
	iowrite32(7, virt_addr+0); //base address + offset
	/* Write 2 to register 1*/
	printk(KERN_INFO "Writing a 2 to register 1\n");
	//use iowrite32
	iowrite32(2, virt_addr+4); //base address + offset

	printk("Read %d from register 0\n", ioread32(virt_addr+0));
	printk("Read %d from register 1\n", ioread32(virt_addr+4));
	printk("Read %d from register 2\n", ioread32(virt_addr+8));

	//a non 0 return means init_module failed; module can't be loaded.
	return 0;
}
/* This function is run just prior to the module's removal from the system. You should release _ALL_ resources used by your module here (otherwise be prepared for a reboot). */
static void __exit my_exit(void) {
	printk(KERN_ALERT "unmapping virtual address space...\n");
	iounmap((void*)virt_addr);
}

/* These define info that can be displayed by modinfo */
MODULE_LICENSE("GPL");
MODULE_AUTHOR("ECEN449 SANKAR M S & BILL PENG");
MODULE_DESCRIPTION("Simple multiplier module");

/* Here we define which functions we want to use for initialization and cleanup */
module_init(my_init);
module_exit(my_exit);
