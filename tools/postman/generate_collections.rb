#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "lib/ion_postman"

exit IonPostman::CLI.run(ARGV)
