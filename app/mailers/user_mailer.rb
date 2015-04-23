class UserMailer < ApplicationMailer
  default from: 'MLB Runs Pool <runspool@danmadere.com>'

  def hit_email(hit)
    @hit = hit
    @url  = standings_url
    mail(to: @hit.entry.user.email, subject: "Congrats! Your team scored #{@hit.runs} runs")
  end
end
