require 'spec_helper'

describe "facility_maps", type: :feature do
  subject(:site) { cms_site }
  subject(:node) { create_once :facility_node_page, name: "facility" }
  subject(:item) { Facility::Map.last }
  subject(:index_path) { facility_maps_path site.id, node }
  subject(:new_path) { new_facility_map_path site.id, node }
  subject(:show_path) { facility_map_path site.id, node, item }
  subject(:edit_path) { edit_facility_map_path site.id, node, item }
  subject(:delete_path) { delete_facility_map_path site.id, node, item }
  let(:addon_titles) { page.all("form .addon-head h2").map(&:text).sort }
  let(:expected_addon_titles) do
    [
      I18n.t("modules.addons.cms/meta"),
      I18n.t("modules.addons.cms/release_plan"),
      I18n.t("modules.addons.cms/release"),
      I18n.t("modules.addons.map/page"),
      I18n.t("ss.basic_info"),
      I18n.t("modules.addons.workflow/approver"),
      I18n.t("modules.addons.cms/group_permission")
    ].sort
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t("ss.buttons.save")
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      expect(addon_titles).to eq expected_addon_titles
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button I18n.t("ss.buttons.save")
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).to have_no_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button I18n.t("ss.buttons.delete")
      end
      expect(current_path).to eq index_path
    end
  end

  context "set center and zoom" do
    before { login_cms_user }
    before do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button I18n.t("ss.buttons.save")
      end
    end

    it "#center position" do
      visit edit_path
      expect(item.center_setting).to eq "auto"
      expect(item.set_center_position).to eq nil
      within "form" do
        find("input[name='item[center_setting]'][value='designated_location']").set(true)
        fill_in "item[set_center_position]", with: "134.589971,34.067035"
        click_on I18n.t("ss.buttons.save")
      end
      item.reload
      expect(item.center_setting).to eq "designated_location"
      expect(item.set_center_position).to eq "134.589971,34.067035"
    end

    it "#center position validation" do
      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "134.589971,90"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).not_to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "134.589971,90.1"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "134.589971,-90"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).not_to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "134.589971,-90.1"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "180,34.067035"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).not_to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "180.1,34.067035"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "-180,34.067035"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).not_to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "-180.1,34.067035"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "34.067035,134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "134.589971,34.067035,134.589971"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "longitude,latitude"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_center_position]", with: "134.589971,34.067abc035"
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")
    end

    it "#zoom level" do
      visit edit_path
      expect(item.zoom_setting).to eq "auto"
      expect(item.set_zoom_level).to eq nil
      within "form" do
        find("input[name='item[zoom_setting]'][value='designated_level']").set(true)
        fill_in "item[set_zoom_level]", with: 10
        click_on I18n.t("ss.buttons.save")
      end
      item.reload
      expect(item.zoom_setting).to eq "designated_level"
      expect(item.set_zoom_level).to eq 10
    end

    it "#zoom level border value" do
      visit edit_path
      within "form" do
        fill_in "item[set_zoom_level]", with: 0
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")

      visit edit_path
      within "form" do
        fill_in "item[set_zoom_level]", with: 1
        click_on I18n.t("ss.buttons.save")
      end
      item.reload
      expect(item.set_zoom_level).to eq 1

      visit edit_path
      within "form" do
        fill_in "item[set_zoom_level]", with: 21
        click_on I18n.t("ss.buttons.save")
      end
      item.reload
      expect(item.set_zoom_level).to eq 21

      visit edit_path
      within "form" do
        fill_in "item[set_zoom_level]", with: 22
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css("#errorExplanation")
    end
  end
end
