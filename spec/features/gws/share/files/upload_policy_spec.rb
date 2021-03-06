require 'spec_helper'

describe "gws_share_files_upload_policy", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:folder) { create :gws_share_folder }
  let!(:category) { create :gws_share_category }

  context "sanitizer setting" do
    before { login_gws_user }

    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
      Fs.mkdir_p(SS.config.ss.sanitizer_input)
      Fs.mkdir_p(SS.config.ss.sanitizer_output)
    end

    after do
      Fs.rm_rf(SS.config.ss.sanitizer_input)
      Fs.rm_rf(SS.config.ss.sanitizer_output)
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    it do
      visit gws_share_files_path(site)
      click_on folder.name

      # create
      click_on I18n.t("ss.links.new")
      click_on I18n.t("gws.apis.categories.index")
      wait_for_cbox do
        click_on category.name
      end
      within "form#item-form #addon-basic" do
        wait_cbox_open do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('.file-view', text: 'keyvisual.jpg')
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      wait_cbox_close do
        click_on "keyvisual.jpg"
      end
      within '#selected-files' do
        expect(page).to have_css('.name', text: 'keyvisual.jpg')
        expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))
      end

      within "form#item-form" do
        fill_in "item[memo]", with: "new test"
      end
      within "footer.send" do
        click_on I18n.t('ss.buttons.upload')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      within '.list-items' do
        expect(page).to have_content('keyvisual.jpg')
        expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))
      end

      file = Gws::Share::File.all.first
      expect(file.sanitizer_state).to eq 'wait'
      expect(Fs.exists?(file.path)).to be_truthy
      expect(Fs.exists?(file.sanitizer_input_path)).to be_truthy
      expect(FileTest.size(file.path)).to eq 2048

      # show
      click_on file.name
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      # restore
      output_path = "#{SS.config.ss.sanitizer_output}/#{file.id}_filename_100_marked.#{file.extname}"
      Fs.mv file.sanitizer_input_path, output_path
      file.sanitizer_restore_file(output_path)
      expect(file.sanitizer_state).to eq 'complete'
      expect(FileTest.size(file.path)).to be > 2048

      click_on I18n.t('ss.links.back_to_index')
      expect(page).to have_no_css('.list-items .sanitizer-wait')
      click_on file.name
      expect(page).to have_no_css('.sanitizer-wait')

      # update
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        fill_in "item[name]", with: "modify"
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
      expect(page).to have_css('.sanitizer-wait', text: I18n.t('ss.options.sanitizer_state.wait'))

      file.reload
      file_path = file.path
      sanitizer_input_path = file.sanitizer_input_path
      expect(FileTest.size(file.path)).to eq 2048

      # soft delete
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      # hard delete
      visit gws_share_files_path(site)
      click_on I18n.t("ss.links.trash")
      click_on folder.name
      click_on file.name
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Fs.exists?(file_path)).to be_falsey
      expect(Fs.exists?(sanitizer_input_path)).to be_falsey
    end
  end

  context "restricted setting" do
    before { login_gws_user }

    before do
      @save_config = SS.config.replace_value_at(:ss, :upload_policy, 'sanitizer')
      site.update_attributes(upload_policy: 'restricted')
    end

    after do
      SS.config.replace_value_at(:ss, :upload_policy, @save_config)
    end

    it do
      visit gws_share_files_path(site)
      click_on folder.name

      # create
      click_on I18n.t("ss.links.new")
      click_on I18n.t("gws.apis.categories.index")
      wait_for_cbox do
        click_on category.name
      end
      within "form#item-form #addon-basic" do
        wait_cbox_open do
          click_on I18n.t('ss.buttons.upload')
        end
      end
      wait_for_cbox do
        attach_file "item[in_files][]", "#{Rails.root}/spec/fixtures/ss/file/keyvisual.jpg"
        click_button I18n.t("ss.buttons.save")
      end
      page.accept_alert do
        expect(page).to have_no_css('.file-view')
      end
      expect(Gws::Share::File.all.count).to eq 0
    end
  end
end
