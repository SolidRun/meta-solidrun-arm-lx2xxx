#@TYPE: Machine
#@NAME: SolidRun LX2160A CEX-7
#@SOC: LSCH3
#@DESCRIPTION: Machine configuration for SolidRun LX2160A 2.0 COM-Express Type 7 Module

# select rev2 rcw
# set before lx2160acex7.inc which uses ?=, too
RCW_FOLDER ?= "lx2160acex7_rev2"

require conf/machine/include/lx2160acex7.inc
