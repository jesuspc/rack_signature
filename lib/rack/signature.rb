require "rack/signature/version"
require "rack/signature/validator"

module Rack
  class Signature
    TIMESTAMP_HEADER = 'Timestamp'.freeze
    SIGNATURE_HEADER = 'Signature'.freeze

    attr_accessor :validator, :signable_elms, :signable_extractor

    def initialize(app, opts = {})
      @app = app
      self.validator = opts.fetch :validator, Validator
      self.signable_elms = opts.fetch :signable_elms, [:params, :body]
      self.signable_extractor = opts.fetch :signable_extractor, SignableExtractor
    end

    def call(env)
      env[:signature] ||= signature_params(env)
      @app.call env
    end

    private

    def signature(env)
      env[:request_headers][SIGNATURE_HEADER]
    end

    def timestamp(env)
      env[:request_headers][TIMESTAMP_HEADER]
    end

    def signature_params(env)
      {
        value: signature(env),
        present: !signature(env).nil?,
        valid: validator.call(signable(env.request), signature(env), timestamp(env))
      }
    end

    def signable(request)
      signable_extractor.call request, signable_elms
    end
  end
end
