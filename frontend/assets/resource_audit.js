function ResourceAudit($resource_audit_form) {
  this.$resource_audit_form = $resource_audit_form;
  this.setup_form();
}

ResourceAudit.prototype.setup_form = function() {
  var self = this;

  $(document).trigger("loadedrecordsubforms.aspace", this.$resource_audit_form);

  //this.$resource_audit_form.on("submit", function(event) {
  //  event.preventDefault();
  //  self.perform_search(self.$resource_audit_form.serializeArray());
  //});
};

$(function() {
  var resourceAudit = new ResourceAudit($("#resource_audit_form"));
});
