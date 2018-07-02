class ArchivesSpaceService < Sinatra::Base

  Endpoint.get('/repositories/:repo_id/resources/:id/audit')
    .description("Audit the selected Resource for metadata completeness")
    .params(["id", :id],
            ["repo_id", :repo_id])
    .permissions(["update_resource_record"])
    .returns([200, "OK"]) \
  do
    json_response(ResourceAudit.new(params[:id]).audit_data)
  end
end
