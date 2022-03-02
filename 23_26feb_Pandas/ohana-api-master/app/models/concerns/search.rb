require 'email_filter'
require 'location_filter'

module Search
  extend ActiveSupport::Concern

  included do
    def nearbys(radius)
      r = LocationFilter.new(self.class).validated_radius(radius, 0.5)
      super(r)
    end

    scope :category, (lambda do |category|
      joins(services: :categories).where(categories: { name: category })
    end)

    scope :is_near, LocationFilter

    scope :org_name, (lambda do |org|
      joins(:organization).where('organizations.name @@ :q', q: org)
    end)

    scope :with_email, EmailFilter
  end

  module ClassMethods
    def status(param)
      param == 'active' ? where(active: true) : where(active: false)
    end

    def keyword(query)
      order_query = Arel.sql("#{rank_for(query)} DESC, locations.updated_at DESC")
      where("locations.tsv_body @@ plainto_tsquery('english', ?)", query).
        order(order_query)
    end

    def rank_for(query)
      sanitized = ActiveRecord::Base.connection.quote(query)

      <<-RANK
        ts_rank(locations.tsv_body, plainto_tsquery('english', #{sanitized}))
      RANK
    end

    def language(lang)
      where('locations.languages && ARRAY[?]', lang)
    end

    def service_area(service_area_param)
      joins(:services).where('services.service_areas @@ :q', q: service_area_param).distinct
    end

    def text_search(params = {})
      allowed_params(params).to_h.reduce(self) do |relation, (scope_name, value)|
        value.present? ? relation.public_send(scope_name, value) : relation.all
      end
    end

    def search(params = {})
      res = text_search(params).
            with_email(params[:email]).
            is_near(params[:location], params[:lat_lng], params[:radius])

      return res unless params[:keyword] && params[:service_area]

      res.select("locations.*, #{rank_for(params[:keyword])}")
    end

    def allowed_params(params)
      params.permit(
        { category: [] }, :category, :keyword, :language, :org_name, :service_area, :status
      )
    end
  end
end
