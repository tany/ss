class Jmaxml::ForecastRegionImportJob < Cms::ApplicationJob
  include SS::ZipFileImport

  private

  def model
    Jmaxml::ForecastRegion
  end

  def import_file
    table = ::CSV.read(@cur_file.path, headers: true, encoding: 'SJIS:UTF-8')
    table.each_with_index do |row, i|
      import_row(row, i)
    end
    nil
  end

  def import_row(row, index)
    code = row[model.t(:code)].presence
    name = row[model.t(:name)].presence
    return if code.blank? || name.blank?

    item = Jmaxml::ForecastRegion.site(self.site).where(code: code).first_or_create(name: name)
    item.name = name
    item.yomi = row[model.t(:yomi)].presence if row[model.t(:yomi)].present?
    item.short_name = row[model.t(:short_name)].presence if row[model.t(:short_name)].present?
    item.short_yomi = row[model.t(:short_yomi)].presence if row[model.t(:short_yomi)].present?
    item.order = row[model.t(:order)].presence if row[model.t(:order)].present?
    item.state = row[model.t(:state)].presence if row[model.t(:state)].present?
    item.save!
  end
end
