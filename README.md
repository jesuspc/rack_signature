# RackSignature

Unobtrusive signed requests.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rack_signature'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack_signature

## Usage

Add Rack::Signature to your rack stack by specifying a hash of key => secret pairs.

```ruby
keystore =  { key: 'secret' }
use Rack::Signature, keystore: keystore
```

The requests going through the middleware will have a 'SIGNATURE' key added with the signature data.

```ruby
request.env['SIGNATURE'] #=> { value: 'blah', present: true, valid: true, key_known: true }
```

In order to validate the signature received by default the middleware is going to inspect the request headers 'Signature_key', 'Signature' and 'Timestamp'.

## Contributing

1. Fork it ( https://github.com/[my-github-username]/rack_signature/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
