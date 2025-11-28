unit module LLM::DWIM;
use LLM::Functions;
use LLM::Prompts;
use JSON::Fast;
use Log::Async;
use TOML;

logger.untapped-ok = True;

state &evaluator;
state $config;

my $default-evaluator = 'OpenAI';
sub conf-file {
  my $base = %*ENV<XDG_HOME> // $*HOME.child('.config');
  %*ENV<DWIM_LLM_CONF> // $base.child('llm-dwim.toml');
}

sub get-llm-config {
  return $config if $config;

  my $conf-file = conf-file;
  $config = do {
    if $conf-file.IO.e {
      debug "Reading configuration from $conf-file";
      from-toml($conf-file.IO.slurp);
    } else {
      debug "No configuration file found at $conf-file, using default: $default-evaluator";
      %( evaluator => $default-evaluator );
    }
  };
  return $config;
}

sub llm-config-thing($conf) {
  my $evaluator = $conf<evaluator> or die "No evaluator in { conf-file } (found: { $conf.keys })";
  my $evaluator-config = $conf{ $evaluator } // {};
  debug "Configuration: $evaluator, { $evaluator-config.raku }";
  llm-configuration( $evaluator, |%( $evaluator-config ) )
}

sub expand($str is copy) {
  my $e = $config<prompt><expansions> or return $str;
  my %exp = %$e;
  $str.subst( / '@' @( %exp.keys ) /, -> $in { %exp{ $in.substr(1) } } );
}

sub dwim(Str $str) is export {
  &evaluator //= llm-function(
    llm-evaluator => llm-config-thing( get-llm-config )
  );
  my $msg = llm-prompt-expand(expand($str));
  debug "sending $msg";
  evaluator($msg);
}

sub dwim-chat(Str $prompt = "", :$id) is export {
  my $conf = get-llm-config();
  my $config = llm-config-thing($conf);
  llm-chat(chat-id => $id || "dwim-chatter-" ~ ++$, conf => $config, :$prompt);
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

my $bot = dwim-chat("Answer every question with an exclamation point!");
say $bot.eval: "My name is bob and I have five dogs.";
# That's great!

say $bot.eval: "How many paws is that?";
# Twenty!

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

    sub dwim(Str $str) returns Str

This function takes a string, expands it using L<LLM::Prompts>, and uses L<LLM::Functions> to
evaluate the string.

=head2 dwim-chat

    sub dwim-chat(Str $prompt) returns Str

Create a chat bot that will have a conversation.

For diagnostics, use L<Log::Async|https://raku.land/cpan:BDUGGAN/Log::Async> and add a tap, like so:

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

You can also add custom prompt expansions like this:

    [prompt.expansions]
       geojson = """
       Respond only in valid GeoJSON.
       """

This will expand @geojson into the text "Respodn only in valid GeoJSON"

See L<LLM::Functions|https://raku.land/zef:antononcube/LLM::Functions> for all of
the configuration options.

=head1 COMMAND LINE USAGE

This package has two scripts:

First, `llm-dwim` can be used to evaluate a string from the command line.

Sample usage:

    llm-dwim -h  # get usage
    llm-dwim "How many miles is it from the earth to the moon?"
    llm-dwim -v how far is it from the earth to the moon\?
    echo "what is the airspeed velocity of an unladen swallow?" | llm-dwim -

Second, `llm-dwim-chat` will have a chat with you.

Sample session:

    llm-dwim-chat you are a french tutor --name=Professor

    you > Hello
    Professor > Bonjour !  Comment allez-vous ?
    you > Bien merci
    Professor > Et vous ?  (And you?)
    you >

=head1 SEE ALSO

L<LLM::Functions|https://raku.land/zef:antononcube/LLM::Functions>,
L<LLM::Prompts|https://raku.land/zef:antononcube/LLM::Prompts>

This was inspired by the also excellent L<DWIM::Block|https://metacpan.org/pod/DWIM::Block> module.

=head1 AUTHOR

Brian Duggan

=end pod

