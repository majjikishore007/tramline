require "irb/completion"
require "rubygems"

IRB.conf[:USE_READLINE] = true
IRB.conf[:SAVE_HISTORY] = 1000
IRB.conf[:HISTORY_FILE] = ".irb-save-history"
IRB.conf[:USE_AUTOCOMPLETE] = false

def A(slug) = App.find_by_slug(slug)
def T(slug) = Train.find_by_slug(slug)
def Rel(slug) = Release.find_by_slug(slug)
def Wrun(id) = WorkflowRun.find(id)
def B(id) = Build.find(id)
def Prun(id) = ReleasePlatformRun(id)
def Csha(sha) = Commit.all.find { |c| c.short_sha == sha }
def U(email) = Accounts::User.find_by_unique_authn_id(email)
