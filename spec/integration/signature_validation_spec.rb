require 'spec_helper'
require 'json'

RSpec.describe 'Signature validation', integration: true do
  subject { Rack::Signature }

  let(:minimal_rack) do

    ->(env) do
      body = env['SIGNATURE'] || {}
      [200, { 'Content-Type' => 'text/html' }, JSON.dump(body)]
    end
  end
  let(:opts) { {} }
  let(:signature) { nil }
  let(:timestamp) { 1 }
  let(:key) { :key }
  let(:secret) { 'extremely_secret_stuff' }

  def app
    @app ||= Rack::Builder.new.tap do |builder|
      builder.use subject, opts
      builder.run minimal_rack
    end
  end

  def do_request
    header 'TIMESTAMP', timestamp
    header 'SIGNATURE', signature
    header 'SIGNATURE_KEY', key
    get '/', { param: 1 }
  end

  context 'when default configuration' do
    let(:opts) { { keystore: { key: secret }, validator_opts: { clock: fake_clock, expiration_time: expiration_time } } }
    let(:fake_clock) { double :fake_clock, now: current_time }
    let(:current_time) { 0 }
    let(:expiration_time) { 10 }

    context 'when the signature is not present' do
      let(:signature) { nil }

      it 'sets the env\'s signature variable appropriately' do
        do_request
        expect(JSON.parse last_response.body).to eq(
          'value' => signature,
          'present' => false,
          'valid' => false,
          'key_known' => true,
          'expired' => false
        )
      end
    end

    context 'when the signature is present' do
      let(:signature) { 'blah' }

      context 'when the signature is valid' do
        let(:signature) do
          Signatures::Signers::Basic.new.call("param=1/#{timestamp}", secret: secret)
        end

        it 'sets the env\'s signature variable appropriately' do
          do_request
          expect(JSON.parse last_response.body).to eq(
            'value' => signature,
            'present' => true,
            'valid' => true,
            'key_known' => true,
            'expired' => false
          )
        end
      end

      context 'when the signature is not valid' do
        it 'sets the env\'s signature variable appropriately' do
          do_request
          expect(JSON.parse last_response.body).to eq(
            'value' => signature,
            'present' => true,
            'valid' => false,
            'key_known' => true,
            'expired' => false
          )
        end
      end

      context 'when the signature is expired' do
        let(:current_time) { 12 }
        let(:timestamp) { 1 }
        let(:expiration_time) { 10 }

        it 'sets the env\'s signature variable appropriately' do
          do_request
          expect(JSON.parse last_response.body).to eq(
                                                     'value' => signature,
                                                     'present' => true,
                                                     'valid' => false,
                                                     'key_known' => true,
                                                     'expired' => true
                                                   )
        end
      end

      context 'when the key is not in the keystore' do
        let(:key) { :missing_key }

        it 'sets the env\'s signature variable appropriately' do
          do_request
          expect(JSON.parse last_response.body).to eq(
            'value' => signature,
            'present' => true,
            'valid' => false,
            'key_known' => false,
            'expired' => false
          )
        end
      end
    end
  end
end
