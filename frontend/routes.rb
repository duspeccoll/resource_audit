ArchivesSpace::Application.routes.draw do
  match('/plugins/resource_audit' => 'resource_audit#index', :via => [:get])
  match('/plugins/resource_audit/submit' => 'resource_audit#submit', :via => [:post])
  match('/plugins/resource_audit/audit' => 'resource_audit#audit', :via => [:get])
end
