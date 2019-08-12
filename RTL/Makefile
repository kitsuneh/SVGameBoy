SYSTEM = soc_system

TCL = $(SYSTEM).tcl
QSYS = $(SYSTEM).qsys
SOPCINFO = $(SYSTEM).sopcinfo
QIP = $(SYSTEM)/synthesis/$(SYSTEM).qip
HPS_PIN_TCL = $(SYSTEM)/synthesis/submodules/hps_sdram_p0_pin_assignments.tcl
HPS_PIN_MAP = hps_sdram_p0_all_pins.txt
QPF = $(SYSTEM).qpf
QSF = $(SYSTEM).qsf
SDC = $(SYSTEM).sdc

BOARD_INFO = $(SYSTEM)_board_info.xml
DTS = $(SYSTEM).dts
DTB = $(SYSTEM).dtb

SOF = output_files/$(SYSTEM).sof
RBF = output_files/$(SYSTEM).rbf

SOFTWARE_DIR = software

BSP_DIR = $(SOFTWARE_DIR)/spl_bsp
BSP_SETTINGS = $(BSP_DIR)/settings.bsp
PRELOADER_SETTINGS_DIR = hps_isw_handoff/soc_system_hps_0
PRELOADER_MAKEFILE = $(BSP_DIR)/Makefile
PRELOADER_MKPIMAGE = $(BSP_DIR)/preloader-mkpimage.bin

UBOOT_IMAGE = $(BSP_DIR)/uboot-socfpga/u-boot.img

KERNEL_REPO = https://github.com/altera-opensource/linux-socfpga.git
KERNEL_BRANCH = socfpga-4.19
DEFAULT_CONFIG = socfpga_defconfig
CROSS = env CROSS_COMPILE=arm-altera-eabi- ARCH=arm

KERNEL_DIR = $(SOFTWARE_DIR)/linux-socfpga
KERNEL_CONFIG = $(KERNEL_DIR)/.config
ZIMAGE = $(KERNEL_DIR)/arch/arm/boot/zImage

TARFILES = Makefile \
	$(TCL) \
	$(QSYS) \
	$(SYSTEM)_top.sv \
	$(BOARD_INFO) \
	ip/intr_capturer/intr_capturer.v \
	ip/intr_capturer/intr_capturer_hw.tcl \
	game_boy.sv

TARFILE = lab3-hw.tar.gz

# project
#
# Run the topmost tcl script to generate the initial project files

.PHONY : project
project : $(QPF) $(QSF) $(SDC)

$(QPF) $(QSF) $(SDC) : $(TCL)
	quartus_sh -t $(TCL)

# qsys
#
# From the .qsys file, generate the .sopcinfo, .qip, and directory
# (named according to the system) with all the Verilog files, etc.

.PHONY : qsys
qsys : $(SOPCINFO)

$(SOPCINFO) $(QIP) $(HPS_PIN_TCL) $(SYSTEM)/ $(PRELOADER_SETTINGS_DIR) : $(QSYS)
	rm -rf $(SOPCINFO) $(SYSTEM)/
	qsys-generate $(QSYS) --synthesis=VERILOG

# quartus
#
# Run Quartus on the Qsys-generated files
#
#    Build netlist
# quartus_map soc_system
#
#    Use netlist information to determine HPS stuff
# quartus_sta -t hps_sdram_p0_pin_assignments.tcl soc_system
#
#    Do the rest
#   FIXME: this is wasteful.  Really want not to repeat the "map" step
# quartus_sh --flow compile 
#
# quartus_fit
# quartus_asm
# quartus_sta

.PHONY : quartus
quartus : $(SOF)

$(SOF) $(HPS_PIN_MAP) : $(QIP) $(QPF) $(QSF) $(HPS_PIN_TCL)
	quartus_map $(SYSTEM)
	quartus_sta -t $(HPS_PIN_TCL) $(SYSTEM)
	quartus_fit $(SYSTEM)
	quartus_asm $(SYSTEM)
#	quartus_sh --flow compile $(QPF)

# rbf
#
# Convert the .sof file (for programming through the USB blaster)
# to an .rbf file to be placed on an SD card and written by u-boot
.PHONY : rbf
rbf : $(RBF)

$(RBF) : $(SOF)
	quartus_cpf -c $(SOF) $(RBF)

# dtb
#
# Use the .sopcinfo file to generate a device tree blob file
# with information about the memory map of the peripherals
.PHONY : dtb
dtb : $(DTB)

$(DTB) : $(DTS)
	dtc -I dts -O dtb -o $(DTB) $(DTS)

$(DTS) : $(SOPCINFO) $(BOARD_INFO)
	sopc2dts --input $(SOPCINFO) \
		--output $(DTS) \
		--type dts \
		--board $(BOARD_INFO) \
		--clocks

# preloader
#
# Builds the SPL's preloader-mkpimage.bin image file, which should
# be written to the "magic" 3rd parition on the SD card
# in software/spl_bsp
#
# Requires the embedded_command_shell.sh script to have run so the compiler,
# etc is available
#
.PHONY : preloader
preloader : $(PRELOADER_MKPIMAGE)

$(PRELOADER_MKPIMAGE) : $(PRELOADER_MAKEFILE) $(BSP_SETTINGS)
	$(MAKE) -C $(BSP_DIR)

$(BSP_SETTINGS) $(PRELOADER_MAKEFILE) : $(PRELOADER_SETTINGS_DIR)
	mkdir -p $(BSP_DIR)
	bsp-create-settings \
	  --type spl \
	  --bsp-dir $(BSP_DIR) \
	  --settings $(BSP_SETTINGS) \
	  --preloader-settings-dir $(PRELOADER_SETTINGS_DIR) \
	  --set spl.boot.FAT_SUPPORT 1

# uboot
#
# Build the bootloader

.PHONY : uboot
uboot : $(UBOOT_IMAGE)

$(UBOOT_IMAGE) : $(PRELOADER_MAKEFILE) $(BSP_SETTINGS)
	$(MAKE) -C $(BSP_DIR) uboot

# kernel-download
#
# Clone the Linux kernel repository
#
# kernel-config
#
#   Set up the kernel configuration
#
# zimage
#
#   Compile the kernel

.PHONY : download-kernel config-kernel zimage
kernel-download : $(KERNEL_DIR)
kernel-config : $(KERNEL_CONFIG)
zimage : $(ZIMAGE)

$(KERNEL_DIR) :
	mkdir -p $(KERNEL_DIR)
	git clone --branch $(KERNEL_BRANCH) $(KERNEL_REPO) $(KERNEL_DIR)

# Configure the kernel.  Start from a provided default,
# 
# Turn off version checking (makes it easier to compile kernel
# modules and not have them complain about version)
#
# Turn on large file (+2TB) support, which the ext4 filesystem
# requires by default (it will not be able to mount the root
# filesystem read/write otherwise)
$(KERNEL_CONFIG) : $(KERNEL_DIR)
	$(CROSS) $(MAKE) -C $(KERNEL_DIR) $(DEFAULT_CONFIG)
	$(KERNEL_DIR)/scripts/config --file $(KERNEL_CONFIG) \
	  --disable CONFIG_LOCALVERSION_AUTO \
	  --enable CONFIG_LBDAF \
	  --disable CONFIG_XFS_FS \
	  --disable CONFIG_GFS2_FS \
	  --disable CONFIG_TEST_KMOD

# Compile the kernel

$(ZIMAGE) : $(KERNEL_CONFIG)
	$(CROSS) $(MAKE) -C $(KERNEL_DIR) LOCALVERSION= zImage

# tar
#
# Build soc_system.tar.gz

.phony : tar
tar : $(TARFILE)

$(TARFILE) : $(TARFILES)
	tar zcfC $(TARFILE) .. $(TARFILES:%=lab3-hw/%)

# clean
#
# Remove all generated files

.PHONY : clean quartus-clean qsys-clean project-clean
clean : quartus-clean qsys-clean project-clean dtb-clean preloader-clean \
	uboot-clean

project-clean :
	rm -rf $(QPF) $(QSF) $(SDC)

qsys-clean :
	rm -rf $(SOPCINFO) $(QIP) $(SYSTEM)/ .qsys_edit \
	hps_isw_handoff/ hps_sdram_p0_summary.csv

quartus-clean :
	rm -rf  $(SOF) output_files db incremental_db $(SYSTEM).qdf \
	c5_pin_model_dump.txt $(HPS_PIN_MAP)

dtb-clean :
	rm -rf $(DTS) $(DTB)

preloader-clean :
	rm -rf $(BSP_DIR)

uboot-clean :
	rm -rf $(BSP_DIR)/uboot-socfpga

kernel-clean :
	rm -rf $(KERNEL_DIR)

config-clean :
	rm -rf $(KERNEL_CONFIG)
