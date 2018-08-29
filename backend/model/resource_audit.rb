class ResourceAudit
  include JSONModel
  include URIResolver

  attr_accessor :audit_data

  def initialize(id)
    @resource = URIResolver.resolve_references(Resource.to_jsonmodel(id), ['linked_agents', 'subjects'])
    @audit_data = {
      'uri' => @resource['uri'],
      'title' => @resource['title'],
      'call_number' => @resource['id_0'],
      'level' => @resource['user_defined']['enum_1']
    }

    resource_audit
  end


  def resource_audit
    audits = []
    audits.push(audit("title", @resource['title']))
    audits.push(audit("call_number", @resource['id_0']))
    audits.push(audit_dates)
    audits.push(audit_extents)
    audits.push(audit_notes("abstract"))
    audits.push(audit_creator)
    audits.push(audit_subjects)
    if ["level_2", "level_3"].include?(@audit_data['level'])
      audits.push(audit_notes("bioghist"))
      audits.push(audit_notes("scopecontent"))
    else
      optional_audits = []
      optional_audits.push(audit_notes("bioghist"))
      optional_audits.push(audit_notes("scopecontent"))
      audits.push({'optional_audits' => optional_audits})
    end

    @audit_data['audits'] = audits
    @audit_data['outcome'] = get_outcome
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

  def audit_dates
    audit = { 'element' => "date" }

    if @resource['dates'].length == 0
      audit['outcome'] = "fail"
      audit['reason'] = "Please provide a date"
    else
      if @resource['dates'].map{|date| date['expression']}.include?("Date Not Yet Determined")
        audit['outcome'] = "partial_pass"
        audit['reason'] = "Date is not yet determined; can you infer it from the collection contents?"
      else
        audit['outcome'] = "pass"
      end
    end

    values = []
    @resource['dates'].each do |date|
      values.push({
        'type' => date['date_type'],
        'value' => date['expression']
      })
    end

    audit['values'] = values

    audit
  end

  def audit_extents
    audit = {'element' => "extent"}
    if @resource['extents'].length == 0
      audit['outcome'] = "fail"
      audit['reason'] = "Please provide an extent (use the Extent Calculator if able)"
    else
      audit['outcome'] = "pass"
      audit['values'] = @resource['extents'].map{|ext| ext['number'] + " " + I18n.t('enumerations.extent_extent_type.' + ext['extent_type'])}
    end

    audit
  end

  def audit_notes(note_type)
    audit = {'element' => note_type}
    ns = @resource['notes'].select{|n| n['type'] == note_type}
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

  def audit_creator
    audit = {'element' => "creator"}
    creators = @resource['linked_agents'].select{|agent| agent['role'] == "creator"}
    if creators.length == 0
      audit['outcome'] = "fail"
      audit['reason'] = "Please specify one or more creators"
    else
      audit['outcome'] = "pass"
      audit['values'] = @resource['linked_agents'].map{|creator| creator['_resolved']['title']}
    end

    audit
  end

  def audit_subjects
    audit = {'element' => "subject"}
    values = []

    @resource['subjects'].each {|subject| values.push(subject['_resolved']['title'])} if @resource['subjects'].length > 0
    agent_creators = @resource['linked_agents'].select{|agent| agent['role'] == "subject"}
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

  def get_outcome
    outcomes = @audit_data['audits'].map{|a| a['outcome']}.uniq
    if outcomes.include?('fail')
      "fail"
    elsif outcomes.include?('partial_pass')
      "partial_pass"
    else
      "pass"
    end
  end
end
