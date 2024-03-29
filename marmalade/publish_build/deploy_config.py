# -*- coding: utf-8 -*-
# Deployment settings for d:\programs\marmalade\6.2\quick\target\quick_prebuilt.
# This file is autogenerated by the mkb system and used by the s3e deployment
# tool during the build process.

config = {}
cmdline = ['D:/Programs/Marmalade/6.2/s3e/makefile_builder/mkb.py', 'D:\\Projects\\match\\marmalade\\match.mkb_temp', '--non-interactive', '--no-make', '--no-ide', '--buildenv=WEB', '--builddir', 'publish_build', '--use-prebuilt', '--deploy-only']
mkb = 'd:/Projects/match/marmalade/match.mkb_temp'
mkf = ['d:\\programs\\marmalade\\6.2\\quick\\quick_prebuilt.mkf']

class DeployConfig(object):
    pass

######### ASSET GROUPS #############

assets = {}

assets['Default'] = [
    ('d:/Projects/match/marmalade/resources', '.', 0),
]

######### DEFAULT CONFIG #############

class DefaultConfig(DeployConfig):
    embed_icf = -1
    name = 'match'
    pub_sign_key = 0
    priv_sign_key = 0
    caption = 'match'
    long_caption = 'match'
    version = [1, 0, 1]
    config = ['d:/Projects/match/marmalade/resources/common.icf', 'd:/Projects/match/marmalade/resources/app.icf']
    data_dir = 'd:/Projects/match/marmalade/resources'
    iphone_link_lib = ['s3eFacebook', 's3eIOSAppStoreBilling', 's3eIOSGameCenter']
    playbook_author = 'Markus Neubrand'
    linux_ext_lib = []
    iphone_link_libdir = ['d:/programs/marmalade/6.2/extensions/s3efacebook/lib/iphone', 'd:/programs/marmalade/6.2/extensions/s3eIOSAppStoreBilling/lib/iphone', 'd:/programs/marmalade/6.2/extensions/s3eIOSGameCenter/lib/iphone']
    playbook_authorid = 'gYAAgDCxVmVIxtv73L0YKwmF82U'
    iphone_link_opts = []
    osx_ext_dll = []
    provider = 'Markus Neubrand'
    android_external_jars = ['d:/programs/marmalade/6.2/extensions/s3eFacebook/lib/android/s3eFacebook.jar']
    android_external_res = []
    android_supports_gl_texture = []
    android_extra_manifest = []
    iphone_link_libdirs = []
    android_extra_application_manifest = []
    splashscreen_auto_onblack = 1
    icon = 'd:/Projects/match/marmalade/resources/assets/icon_1.png'
    win32_ext_dll = []
    android_so = ['d:/programs/marmalade/6.2/extensions/s3eFacebook/lib/android/libs3eFacebook.so']
    iphone_link_libs = []
    iphone_sign_for_distribution = 1
    target = {
         'arm' : {
                   'debug'   : r'd:\programs\marmalade\6.2\quick\target\quick_prebuilt_d.s3e',
                   'release' : r'd:\programs\marmalade\6.2\quick\target\quick_prebuilt.s3e',
                 },
         'mips_gcc' : {
                   'debug'   : r'd:\programs\marmalade\6.2\quick\target\quick_prebuilt_d.so',
                   'release' : r'd:\programs\marmalade\6.2\quick\target\quick_prebuilt.so',
                 },
         'x86' : {
                   'debug'   : r'd:\programs\marmalade\6.2\quick\target\quick_prebuilt_d.s86',
                   'release' : r'd:\programs\marmalade\6.2\quick\target\quick_prebuilt.s86',
                 },
         'arm_gcc' : {
                   'debug'   : r'd:\programs\marmalade\6.2\quick\target\quick_prebuilt_d.s3e',
                   'release' : r'd:\programs\marmalade\6.2\quick\target\quick_prebuilt.s3e',
                 },
        }
    assets = assets['Default']

default = DefaultConfig()

######### Configuration: Windows

c = DeployConfig()
config['Windows'] = c
c.os = ['win32']
c.arch = ['x86']
c.target_folder = 'Windows'

######### Configuration: Mac OS X

c = DeployConfig()
config['Mac OS X'] = c
c.os = ['osx']
c.arch = ['x86']
c.target_folder = 'Mac OS X'
