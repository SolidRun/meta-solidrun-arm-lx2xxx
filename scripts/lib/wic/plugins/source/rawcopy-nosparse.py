#
# SPDX-License-Identifier: MIT
#
# wic source plugin "rawcopy-nosparse": same as rawcopy, but without holes.
#
# rawcopy copies the file with sparse_copy, which keeps the holes of the source file.
# Files restored from sstate have holes wherever they hold blocks of zeros (sstate archives
# are created with tar --sparse), e.g. in the MC firmware. These blocks end up unallocated
# in the wic image and are left out of its bmap file (bmaptool create), so writing the image
# with bmaptool would keep the previous content of the target device in their place.
#
# This plugin rewrites the copy as a regular file with all blocks allocated, so the whole
# partition content up to the end of the file is mapped in the bmap file.
# Space beyond the end of the file (e.g. --fixed-size) is not written, and stays unmapped.
#

import logging
import os

from wic.pluginbase import PluginMgr, SourcePlugin

logger = logging.getLogger('wic')

class RawCopyNoSparsePlugin(SourcePlugin):
    """
    Populate partition content from raw image file, without holes.
    """

    name = 'rawcopy-nosparse'

    @classmethod
    def do_prepare_partition(cls, part, source_params, cr, cr_workdir,
                             oe_builddir, bootimg_dir, kernel_dir,
                             rootfs_dir, native_sysroot):
        rawcopy = PluginMgr.get_plugins('source')['rawcopy']
        rawcopy.do_prepare_partition(part, source_params, cr, cr_workdir,
                                     oe_builddir, bootimg_dir, kernel_dir,
                                     rootfs_dir, native_sysroot)

        # rewrite the copy with plain writes, which allocate every block (also zeros)
        dense = part.source_file + '.nosparse'
        with open(part.source_file, 'rb') as src, open(dense, 'wb') as dst:
            while True:
                buf = src.read(1024 * 1024)
                if not buf:
                    break
                dst.write(buf)
        os.replace(dense, part.source_file)
        logger.debug("rawcopy-nosparse: %s has no holes", part.source_file)
