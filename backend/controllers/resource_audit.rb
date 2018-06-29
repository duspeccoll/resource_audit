class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/resources/:id/audit')
    .description("Audit the selected Resource for metadata completeness")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions(["update_resource_record"])
    .returns([200, "OK"]) \
  do
    json_response(resource_audit(resolve_references(Resource.to_jsonmodel(params[:id]), ['linked_agents', 'subjects'])))
  end

  private

  def audit(element, value)
    audit = {'element' => element}
    if value.nil?
      audit['outcome'] = "fail"
      audit['reason'] = "Please provide a value for #{element}"
    else
      audit['outcome'] = "pass"
      audit['value'] = value
    end

    audit
  end

  def audit_dates(dates)
    audit = { 'element' => "date" }

    if dates.length == 0
      audit['outcome'] = "fail"
      audit['reason'] = "Please provide a date"
    else
      if dates.map{|date| date['expression']}.include?("Date Not Yet Determined")
        audit['outcome'] = "partial_pass"
        audit['reason'] = "Date is not yet determined; can you infer it from the collection contents?"
      else
        audit['outcome'] = "pass"
      end
    end

    values = []
    dates.each do |date|
      values.push({
        'type' => date['date_type'],
        'value' => date['expression']
      })
    end

    audit['values'] = values

    audit
  end

  def audit_extents(extents)
    audit = {'element' => "extent"}
    if extents.length == 0
      audit['outcome'] = "fail"
      audit['reason'] = "Please provide an extent (use the Extent Calculator if able)"
    else
      audit['outcome'] = "pass"
      audit['values'] = extents.map{|ext| ext['number'] + " " + I18n.t('enumerations.extent_extent_type.' + ext['extent_type'])}
    end

    audit
  end

  def audit_notes(note_type, notes)
    audit = {'element' => note_type}
    ns = notes.select{|n| n['type'] == note_type}
    if ns.length == 0
      audit['outcome'] = "fail"
      audit['reason'] = "Please provide a #{note_type} note"
    elsif ns.length == 1
      audit['outcome'] = "pass"
      note = ns[0]
      audit['value'] = case note['jsonmodel_type']
      when "note_singlepart"
        note['content'].join(" ")
      when "note_multipart"
        note['subnotes'].map{|subnote| subnote['content']}.join(" ")
      end
    else
      audit['outcome'] = "fail"
      audit['reason'] = "Please make sure you have only one #{note_type} note"
    end

    audit
  end

  def audit_creator(linked_agents)
    audit = {'element' => "creator"}
    creators = linked_agents.select{|agent| agent['role'] == "creator"}
    if creators.length == 0
      audit['outcome'] = "fail"
      audit['reason'] = "Please specify one or more creators"
    else
      audit['outcome'] = "pass"
      audit['values'] = creators.map{|creator| creator['_resolved']['title']}
    end

    audit
  end

  def audit_subjects(agents, subjects)
    audit = {'element' => "subject"}
    values = []

    subjects.each {|subject| values.push(subject['_resolved']['title'])} if subjects.length > 0
    agent_creators = agents.select{|agent| agent['role'] == "subject"}
    agent_creators.each {|agent| values.push(agent['_resolved']['title'])}

    if values.length < 3
      audit['outcome'] = "fail"
      audit['reason'] = "Please provide at least three subject headings (including Agents)"
    else
      audit['outcome'] = "pass"
    end

    audit['values'] = values

    audit
  end

  def get_outcome(audits)
    outcomes = audits.map{|a| a['outcome']}.uniq
    if outcomes.include?('fail')
      "fail"
    elsif outcomes.include?('partial_pass')
      "partial_pass"
    else
      "pass"
    end
  end

  def resource_audit(resource)
    json = {
      'uri' => resource['uri'],
      'title' => resource['title'],
      'call_number' => resource['id_0'],
      'level' => resource['user_defined']['enum_1']
    }

    audits = []
    audits.push(audit("title", resource['title']))
    audits.push(audit("call_number", resource['id_0']))
    audits.push(audit_dates(resource['dates']))
    audits.push(audit_extents(resource['extents']))
    audits.push(audit_notes("abstract", resource['notes']))
    audits.push(audit_creator(resource['linked_agents']))
    audits.push(audit_subjects(resource['linked_agents'], resource['subjects']))
    if ["level_2", "level_3"].include?(json['level'])
      audits.push(audit_notes("bioghist", resource['notes']))
      audits.push(audit_notes("scopecontent", resource['notes']))
    else
      optional_audits = []
      optional_audits.push(audit_notes("bioghist", resource['notes']))
      optional_audits.push(audit_notes("scopecontent", resource['notes']))
      audits.push({'optional_audits' => optional_audits})
    end

    json['audits'] = audits
    json['outcome'] = get_outcome(audits)

    json
  end
end
