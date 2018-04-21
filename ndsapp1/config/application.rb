require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Ndsapp1
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.after_initialize do
      update_database
    end

    def update_database

      @delta_stream = DeltaStream.find_by_id(1)
      @delta_stream = DeltaStream.create(id: 1, frequency_minutes: 60, delta_reachback: 120) if @delta_stream.nil?
#      puts @delta_stream.id 
#      @delta_request = @delta_stream.delta_requests.create()
#      puts @delta_request.id 
#      @notam = @delta_request.notams.create()
#      puts @notam.id 
      @delta_stream.fill_database
      
    end
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end

end

