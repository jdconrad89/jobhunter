# Be sure to restart your server when you modify this file.

# Content Security Policy — report-only for now so we can monitor violations
# before enforcing. Tighten script-src (remove :unsafe_inline) once inline
# scripts are moved to Stimulus/importmap.
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, "https://cdn.jsdelivr.net", :unsafe_inline
    policy.style_src   :self, :unsafe_inline
    policy.connect_src :self
    policy.frame_ancestors :none
    policy.base_uri :self
  end

  config.content_security_policy_report_only = true
end
