use strict;
use warnings;

use Module::Build;

Module::Build->new(
    module_name        => 'TAP::Formatter::Cucumber',
    requires           => { 'Test::Cukes' => '0.10', }, # TODO
    configure_requires => { 'Module::Build' => '0.38', },
    create_makefile_pl => 'small',
    license            => 'perl',
    resources          => {
        repository => {
            type => 'git',
            web  => 'https://github.com/mattlaw/TAP-Formatter-Cucumber',
        },
    },
)->create_build_script;
