use LLM::DWIM;

# optional logging
# use Log::Async;
# logger.send-to($*ERR);

say dwim "How many miles is it from earth is the moon?";

say dwim "@NothingElse How many miles is it from earth is the moon? #NumericOnly";

sub calculate($from,$to) {
  dwim "@NothingElse #NumericOnly What is the distance in miles between $from and $to?";
}

say calculate("earth","sun");
