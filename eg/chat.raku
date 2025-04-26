#!/usr/bin/env raku

use LLM::DWIM;

my $agent = dwim-chat("Answer every question with an exclamation point!");

say $agent.eval: "My name is bob and I have five dogs.";

say $agent.eval: "How many paws is that?";

say $agent.eval: "How many tails?";

