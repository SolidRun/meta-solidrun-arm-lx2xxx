# Sync TODO: lx2160a_build

> This file is generated and maintained by an LLM agent following
> [.agents/skills/sync-lx2160a-build](.agents/skills/sync-lx2160a-build/SKILL.md).
> Do not edit it by hand - every sync rewrites it. Decisions on open points are given to the agent,
> which implements them or proposes accepted omissions for the skill's project-map.md.

Open points of the sync with the SolidRun reference BSP lx2160a_build, i.e. what it has and this layer does not,
grouped by the sync that first found them (newest first).

## develop-ls-6.6.52-2.2.0 @ 989c11e64a463533879b151acf1a23cfc2db0caa (2026-10-02)

First run of the sync skill: these are long-standing omissions, not changes of this sync range.
The RCW and DPC/DPL sources of all SerDes variants below are already in the layer (rcw and mc-utils patches),
but no machine or documented option selects them; only local.conf overrides of `RCW*`/`MC_DPC`/`MC_DPL` could.

### Boards and SerDes variants

- [ ] **LX2160A_CEX7_CLEARFOG-CX_4_5_*** (runme.sh): SD1 protocol 4; same DPC/DPL (`clearfog-cx-s1_8-s2_0`),
  device tree and u-boot as 18_5_* (machines `lx2160a-clearfog-cx` / `lx2160a-rev2-clearfog-cx`), only RCW
  `clearfog-cx/rcw_*_4_5_*` differs. Needs a machine or an option selecting the SD1 protocol.
- [ ] **LX2160A_CEX7_CLEARFOG-CX_8_5_*** (runme.sh): SD1 protocol 8 (8x10G per runme.sh comment); as above with RCW `clearfog-cx/rcw_*_8_5_*`.
- [ ] **LX2160A_CEX7_CLEARFOG-CX_8S_5_*** (runme.sh): SD1 protocol 8S; as above with RCW `clearfog-cx/rcw_*_8S_5_*`.
- [ ] **LX2160A_CEX7_CLEARFOG-CX_20_5_*** (runme.sh): SD1 protocol 20 (QSFP 40G + 4x 10G per mc-utils patch); RCW
  `clearfog-cx/rcw_*_20_5_*` and dedicated DPC/DPL `clearfog-cx-s1_20-s2_0-{dpc,dpl}.dtb`.
- [ ] **LX2160A_CEX7_HONEYCOMB_4_5_*** (runme.sh): no machine; HoneyComb device tree `fsl-lx2160a-honeycomb` with
  Clearfog-CX RCW (`RCW_BOARD=CLEARFOG-CX`) `clearfog-cx/rcw_*_4_5_*` and DPC/DPL `clearfog-cx-s1_8-s2_0`.
- [ ] **LX2160A_CEX7_HONEYCOMB_8S_5_*** (runme.sh): no machine; as above with RCW `clearfog-cx/rcw_*_8S_5_*`.
- [ ] **LX2160A_CEX7_HONEYCOMB_20_5_*** (runme.sh): no machine; for Clearfog-CX board revision 1.2 and earlier
  (QSFP without retimer): RCW `clearfog-cx/rcw_*_20_5_*`, DPC/DPL `clearfog-cx-s1_20-s2_0`.
- [ ] **LX2162A_SOM_CLEARFOG_3_9_0** (runme.sh): SD1 protocol 3 (4x10G on SFP); same DPC/DPL (`clearfog-s1_3-s2_9`),
  device tree and u-boot as 18_9_0 (machine `lx2162a-rev2-clearfog`), only RCW `clearfog/rcw_*_3_9_0_*` differs.
- [ ] **LX2162A_SOM_CLEARFOG_3_7_0** (runme.sh): SD1 protocol 3, SD2 protocol 7; DPC/DPL `clearfog-s1_3-s2_7-{dpc,dpl}.dtb`, RCW `clearfog/rcw_*_3_7_0_*`.
- [ ] **LX2162A_SOM_CLEARFOG_3_11_0** (runme.sh): SD1 protocol 3, SD2 protocol 11; DPC/DPL `clearfog-s1_3-s2_7`, RCW `clearfog/rcw_*_3_11_0_*`.
- [ ] **LX2162A_SOM_CLEARFOG_18_7_0** (runme.sh): SD1 protocol 18, SD2 protocol 7; DPC/DPL `clearfog-s1_3-s2_7`, RCW `clearfog/rcw_*_18_7_0_*`.
- [ ] **LX2162A_SOM_CLEARFOG_18_11_0** (runme.sh): SD1 protocol 18, SD2 protocol 11; DPC/DPL `clearfog-s1_3-s2_7`, RCW `clearfog/rcw_*_18_11_0_*`.
