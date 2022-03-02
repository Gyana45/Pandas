require 'rails_helper'

describe 'Services page' do
  context 'when not signed in' do
    before do
      visit '/admin/services'
    end

    it 'redirects to the admin sign in page' do
      expect(page).to have_current_path(new_admin_session_path, ignore_query: true)
    end

    it 'prompts the user to sign in or sign up' do
      expect(page).
        to have_content 'You need to sign in or sign up before continuing.'
    end

    it 'does not include a link to services in the navigation' do
      within '.navbar' do
        expect(page).not_to have_link I18n.t('admin.buttons.services'), href: admin_services_path
      end
    end
  end

  context 'when signed in' do
    before do
      login_admin
      visit '/admin/services'
    end

    it 'displays instructions for editing services' do
      expect(page).to have_content 'Below you should see a list of services'
      expect(page).to have_content 'To start updating, click on one of the links'
      expect(page).not_to have_content 'As a super admin'
    end

    it 'only shows links that belong to the admin' do
      nearby = create(:nearby_loc)
      nearby.services.
        create!(attributes_for(:service).merge(name: 'Nearby Service'))

      loc = create(:location_for_org_admin)
      loc.services.create!(attributes_for(:service))

      visit '/admin/services'
      expect(page).not_to have_link 'Nearby Service'
      expect(page).to have_link 'Literacy Program'
    end
  end

  context 'when signed in as super admin' do
    before do
      @nearby = create(:nearby_loc)
      @service = @nearby.services.
                 create!(attributes_for(:service).
                 merge(name: 'Nearby Service'))

      loc = create(:location_for_org_admin)
      loc.services.create!(attributes_for(:service))

      login_super_admin
      visit '/admin/services'
    end

    it 'displays instructions for editing services' do
      expect(page).to have_content 'As a super admin'
    end

    it 'shows all services' do
      expect(page).to have_link 'Nearby Service'
      expect(page).to have_link 'Literacy Program'
    end

    it 'takes you to the right service when clicked' do
      click_link 'Nearby Service'
      expect(page).
        to have_current_path edit_admin_location_service_path(@nearby.id, @service),
                             ignore_query: true
    end

    it 'sorts services alphabetically by name' do
      expect(page.all('a')[9][:href]).
        to eq "/admin/locations/#{@nearby.id}/services/#{@service.id}/edit"
    end
  end
end
