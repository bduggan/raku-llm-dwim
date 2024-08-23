unit module LLM::DWIM;
use LLM::Functions;
use LLM::Prompts;
use JSON::Fast;
use Log::Async;
use TOML;

logger.untapped-ok = True;

state &evaluator;

my $default-evaluator = 'OpenAI';

sub dwim(Str $str) is export {
  my $base = %*ENV<XDG_HOME> // $*HOME.child('.config');
  my $conf-file = %*ENV<DWIM_LLM_CONF> // $base.child('llm-dwim.toml');
  my $conf = do {
    if $conf-file.IO.e {
      debug "Reading configuration from $conf-file";
      from-toml($conf-file.IO.slurp);
    } else {
      debug "No configuration file found at $conf-file, using default: $default-evaluator";
      %( evaluator => $default-evaluator );
    }
  }
  my $evaluator = $conf<evaluator> or die "No evaluator in $conf-file (found: { $conf.keys })";
  my $evaluator-config = $conf{ $evaluator } // {};
  debug "Configuration: $evaluator, { $evaluator-config.raku }";
  &evaluator //= llm-function(
    llm-evaluator => llm-configuration( $evaluator, |%( $evaluator-config ) )
  );
  my $msg = llm-prompt-expand($str);
  debug "sending $msg";
  evaluator($msg);
}

=begin pod

=head1 NAME

LLM::DWIM -- Do What I Mean, with help from large language models.

=head1 SYNOPSIS

=begin code

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

=end code

Meanwhile, in ~/.config/llm-dwim.toml:

=begin code

evaluator = "gemini"
gemini.temperature = 0.5

=end code

=head1 DESCRIPTION

This is a simple wrapper around L<LLM::Functions|https://raku.land/zef:antononcube/LLM::Functions>,
and L<LLM::Prompts|https://raku.land/zef:antononcube/LLM::Prompts>
It provides a single subroutine, C<dwim>, that sends a string to an LLM evaluator, making use of
a configuration file to say a little more about what you mean.

=head1 FUNCTIONS

=head2 dwim

    sub dwim(Str $str) returns Mu

This function takes a string, expands it using L<LLM::Prompts>, and uses L<LLM::Functions> to
evaluate the string.

It is mostly equivalent to:

=begin code

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

=end code

For diagnostics, use C<L<Log::Async>> and add a tap, like so:

=begin code

use LLM::DWIM;
use Log::Async;

logger.send-to($*ERR);

say dwim "How many miles is it from earth is the moon? #NumericOnly";

=end code

=head1 CONFIGURATION

This module looks for C<llm-dwim.toml> in either C<XDG_HOME> or C<HOME/.config>.
This can be overridden by setting C<DWIM_LLM_CONF> to another filename.

The configuration file should be in TOML format and should contain at least one key,
C<evaluator>, which should be the name of the LLM evaluator to use.  Evaluators
can be configured using TOML syntax, with the evaluator name as the key.

Sample configurations:

Use Gemini (which has a free tier) :

=begin code

evaluator = "gemini"

=end code

Use OpenAI, and modify some parameters:

=begin code

evaluator = "OpenAI"
OpenAI.temperature = 0.9
OpenAI.max-tokens = 100

=end code

See L<LLM::Functions|https://raku.land/zef:antononcube/LLM::Functions> for all of
the configuration options.

Also, this package includes a `llm-dwim` script that can be used
to evaluate a string from the command line. It will look for the
configuration file in the same way as the module.

Sample usage:

    llm-dwim "How many miles is it from the earth to the moon?"
    llm-dwim -v how far is it from the earth to the moon\?
    echo "what is the airspeed velocity of an unladen swallow?" | llm-dwim -

=head1 SEE ALSO

L<LLM::Functions|https://raku.land/zef:antononcube/LLM::Functions>,
L<LLM::Prompts|https://raku.land/zef:antononcube/LLM::Prompts>

This was inspired by the also excellent L<DWIM::Block|https://metacpan.org/pod/DWIM::Block> module.

=head1 AUTHOR

Brian Duggan

=end pod

