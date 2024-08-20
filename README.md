[![Actions Status](https://github.com/bduggan/raku-llm-dwim/actions/workflows/linux.yml/badge.svg)](https://github.com/bduggan/raku-llm-dwim/actions/workflows/linux.yml)
[![Actions Status](https://github.com/bduggan/raku-llm-dwim/actions/workflows/macos.yml/badge.svg)](https://github.com/bduggan/raku-llm-dwim/actions/workflows/macos.yml)

NAME
====

LLM::DWIM -- Do What I Mean, with help from large language models.

SYNOPSIS
========

    use LLM::DWIM;

    say dwim "How many miles is it from the earth to the moon?";
    # Approximately 238,900 miles (384,400 kilometers)

    say dwim "@NothingElse How many miles is it from the earth to the moon? #NumericOnly";
    # 238900

    sub distance-between($from,$to) {
      dwim "@NothingElse #NumericOnly What is the distance in miles between $from and $to?";
    }

    say distance-between("earth","sun");
    # 92955887.6 miles

Meanwhile, in ~/.config/llm-dwim.toml:

    evaluator = "gemini"
    gemini.temperature = 0.5

DESCRIPTION
===========

This is a simple wrapper around [LLM::Functions](https://raku.land/zef:antononcube/LLM::Functions), and [LLM::Prompts](https://raku.land/zef:antononcube/LLM::Prompts) It provides a single subroutine, `dwim`, that sends a string to an LLM evaluator, making use of a configuration file to say a little more about what you mean.

FUNCTIONS
=========

dwim
----

    sub dwim(Str $str) returns Mu

This function takes a string, expands it using [LLM::Prompts](LLM::Prompts), and uses [LLM::Functions](LLM::Functions) to evaluate the string.

It is mostly equivalent to:

    use LLM::Functions;
    use LLM::Prompts;
    use TOML;

    my $conf-dir = %*ENV<XDG_HOME> // $*HOME.child('.config');
    my $conf = from-toml($conf-dir.child('llm-dwim.toml').IO.slurp);
    my $evaluator = $conf<evaluator>;
    my &evaluator //= llm-function(
        llm-evaluator => llm-configuration( $evaluator, |%( $conf{ $evaluator } ) )
    );
    my $msg = llm-prompt-expand($str);
    evaluator($msg);

For diagnostics, use `L<Log::Async>` and add a tap, like so:

    use LLM::DWIM;
    use Log::Async;

    logger.send-to($*ERR);

    say dwim "How many miles is it from earth is the moon? #NumericOnly";

CONFIGURATION
=============

This module looks for `llm-dwim.toml` in either `XDG_HOME` or `HOME/.config`. This can be overridden by setting `DWIM_LLM_CONF` to another filename.

The configuration file should be in TOML format and should contain at least one key, `evaluator`, which should be the name of the LLM evaluator to use. Evaluators can be configured using TOML syntax, with the evaluator name as the key.

Sample configurations:

Use Gemini (no API key required) :

    evaluator = "gemini"

Use OpenAI, and modify some parameters:

    evaluator = "OpenAI"
    OpenAI.temperature = 0.9
    OpenAI.max-tokens = 100

See [LLM::Functions](https://raku.land/zef:antononcube/LLM::Functions) for all of the configuration options.

SEE ALSO
========

[LLM::Functions](https://raku.land/zef:antononcube/LLM::Functions), [LLM::Prompts](https://raku.land/zef:antononcube/LLM::Prompts)

This was inspired by the also excellent [DWIM::Block](https://metacpan.org/pod/DWIM::Block) module.

AUTHOR
======

Brian Duggan

