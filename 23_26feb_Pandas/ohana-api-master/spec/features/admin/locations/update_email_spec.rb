require 'rails_helper'

describe 'Update email' do
  before do
    @location = create(:location)
    login_super_admin
    visit '/admin/locations/vrs-services'
  end

  it 'with valid location email' do
    fill_in 'location_email', with: 'foo@bar.com'
    click_button I18n.t('admin.buttons.save_changes')
    expect(find_field('location_email').value).to eq 'foo@bar.com'
  end

  it 'with invalid location email' do
    fill_in 'location_email', with: 'foobar.com'
    click_button I18n.t('admin.buttons.save_changes')
    expect(page).to have_content 'foobar.com is not a valid email'
  end
end
