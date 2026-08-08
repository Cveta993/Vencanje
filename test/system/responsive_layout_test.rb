require "application_system_test_case"

class ResponsiveLayoutTest < ApplicationSystemTestCase
  setup do
    @invitation = Invitation.create!(first_name: "Milica", last_name: "Jovanović")
  end

  test "invitation sections fit a phone viewport" do
    emulate_phone(width: 390, height: 844)
    visit invitation_path(@invitation.access_token)

    assert_selector ".invitation-nav a[href='#top']", text: "Početak"
    assert_selector ".invitation-nav a[href='#plan']", text: "Plan"
    assert_selector ".invitation-nav a[href='#rsvp']", text: "Potvrda"
    assert_selector ".invitation-nav a[href='#gallery']", text: "Galerija"
    assert_selector "#invitation-title", text: "Aleksa & Valentina"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=,
      page.evaluate_script("window.innerWidth")
    assert_element_inside_viewport("#invitation-title")
    capture("invitation-mobile-hero")

    scroll_to_section("#plan")
    assert_text "Plan venčanja"
    capture("invitation-mobile-plan")

    scroll_to_section("#rsvp")
    assert_text "Dolazite li?"
    assert_text "najkasnije do 15.05.2027."
    capture("invitation-mobile-rsvp")

    scroll_to_section("#gallery")
    assert_selector "#gallery.gallery-anchor", visible: :all
  ensure
    clear_phone_emulation
  end

  test "desktop schedule and response sections render after scrolling" do
    page.current_window.resize_to(1440, 1100)
    visit invitation_path(@invitation.access_token)

    scroll_to_section("#plan")
    assert_text "JEDAN DAN · TRI LEPA TRENUTKA"
    assert_selector ".event-card", count: 3
    capture("invitation-desktop-plan")

    scroll_to_section("#rsvp")
    assert_text "Za svakog gosta unesite ime i prezime"
    assert_button "Pošalji odgovor"
    capture("invitation-desktop-rsvp")
  end

  test "sticky navigation scrolls to every invitation section" do
    page.current_window.resize_to(1440, 900)
    visit invitation_path(@invitation.access_token)
    page.execute_script("document.documentElement.style.scrollBehavior = 'auto'")

    previous_scroll = page.evaluate_script("window.scrollY")

    { "#plan" => "Plan", "#rsvp" => "Potvrda" }.each do |target, label|
      find(".invitation-nav a[href='#{target}']", text: label, exact_text: true).click
      Selenium::WebDriver::Wait.new(timeout: 2).until do
        page.evaluate_script("window.scrollY") > previous_scroll
      end
      current_scroll = page.evaluate_script("window.scrollY")
      assert_operator current_scroll, :>, previous_scroll
      previous_scroll = current_scroll
      assert_in_delta 0, page.evaluate_script("document.querySelector('.invitation-nav').getBoundingClientRect().top"), 1
    end

    find(".invitation-nav a[href='#gallery']", text: "Galerija", exact_text: true).click
    Selenium::WebDriver::Wait.new(timeout: 2).until do
      page.evaluate_script("window.location.hash") == "#gallery"
    end
    gallery_position = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const gallery = document.querySelector("#gallery").getBoundingClientRect()
        return { top: gallery.top, bottom: gallery.bottom, viewportHeight: window.innerHeight }
      })()
    JAVASCRIPT
    assert_operator page.evaluate_script("window.scrollY"), :>=, previous_scroll
    assert_operator gallery_position["top"], :<=, gallery_position["viewportHeight"] + 1
    assert_operator gallery_position["bottom"], :>=, -1
    assert_in_delta 0, page.evaluate_script("document.querySelector('.invitation-nav').getBoundingClientRect().top"), 1

    find(".invitation-nav a[href='#top']", text: "Početak", exact_text: true).click
    Selenium::WebDriver::Wait.new(timeout: 2).until do
      page.evaluate_script("window.scrollY") < previous_scroll
    end
    assert_operator page.evaluate_script("window.scrollY"), :<, previous_scroll
  end

  test "desktop reveals the invitation with the middle image in one third of the viewport" do
    page.current_window.resize_to(1440, 900)
    visit invitation_path(@invitation.access_token)

    Selenium::WebDriver::Wait.new(timeout: 2).until do
      panel_metrics["schedulePhotoTop"].abs <= 3
    end

    top = panel_metrics
    middle_band = top["viewportHeight"] / 3.0
    primary_band = top["viewportHeight"] - middle_band
    capture("invitation-desktop-top")
    assert_in_delta primary_band, top["heroHeight"], 3
    assert_in_delta primary_band, top["heroBottom"], 3
    assert_in_delta primary_band, top["planTop"], 3
    assert_in_delta middle_band, top["planHeight"], 3
    assert_in_delta top["viewportHeight"], top["planBottom"], 3
    assert_in_delta top["viewportHeight"], top["rsvpTop"], 3
    assert_in_delta 0, top["schedulePhotoTop"], 3
    assert_in_delta top["viewportHeight"], top["schedulePhotoHeight"], 3
    assert_in_delta top["planBottom"], top["schedulePhotoBottom"], 3
    assert_in_delta top["schedulePhotoHeight"] - top["planHeight"],
      top["planTop"] - top["schedulePhotoTop"], 3
    assert_in_delta 0, top["scheduleObjectY"], 0.01
    assert_equal "rgba(0, 0, 0, 0)", top["navBackgroundColor"]
    refute_equal "none", top["navBackgroundImage"]
    assert top["navOverHero"]

    page.execute_script(<<~JAVASCRIPT, top["heroHeight"])
      document.documentElement.style.scrollBehavior = "auto"
      window.scrollTo(0, arguments[0])
    JAVASCRIPT

    Selenium::WebDriver::Wait.new(timeout: 2).until do
      (page.evaluate_script("window.scrollY") - top["heroHeight"]).abs <= 3
    end
    Selenium::WebDriver::Wait.new(timeout: 2).until do
      metrics = panel_metrics
      (metrics["schedulePhotoTop"] - metrics["planTop"]).abs <= 3
    end

    revealed = panel_metrics
    capture("invitation-desktop-revealed")
    assert_in_delta 0, revealed["heroBottom"], 3
    assert_in_delta 0, revealed["planTop"], 3
    assert_in_delta middle_band, revealed["planHeight"], 3
    assert_in_delta middle_band, revealed["planBottom"], 3
    assert_in_delta middle_band, revealed["rsvpTop"], 3
    assert_in_delta revealed["planTop"], revealed["schedulePhotoTop"], 3
    assert_in_delta revealed["viewportHeight"], revealed["schedulePhotoHeight"], 3
    assert_in_delta primary_band,
      revealed["viewportHeight"] - revealed["planBottom"], 3
    assert_operator revealed["rsvpFormTop"], :>, revealed["rsvpTop"]
    assert_operator revealed["rsvpFormTop"] - revealed["rsvpTop"], :<, 60

    page.execute_script("window.scrollTo(0, document.documentElement.scrollHeight)")
    Selenium::WebDriver::Wait.new(timeout: 2).until do
      at_bottom = page.evaluate_script("window.scrollY + window.innerHeight") >=
        page.evaluate_script("document.documentElement.scrollHeight") - 3
      photos_anchored = panel_metrics.then do |metrics|
        (metrics["schedulePhotoTop"] - metrics["planTop"]).abs <= 3 &&
          (metrics["rsvpPhotoTop"] - metrics["planBottom"]).abs <= 3
      end
      at_bottom && photos_anchored
    end

    bottom = panel_metrics
    capture("invitation-desktop-bottom")
    assert_in_delta 0, bottom["planTop"], 3
    assert_in_delta middle_band, bottom["planHeight"], 3
    assert_in_delta middle_band, bottom["planBottom"], 3
    assert_in_delta primary_band,
      bottom["viewportHeight"] - bottom["planBottom"], 3
    assert_operator bottom["rsvpBottom"], :<=, bottom["viewportHeight"] + 1
    assert_equal "sticky", bottom["planPosition"]
    assert bottom["upperShowsPlan"]
    assert bottom["lowerShowsRsvp"]
    assert bottom["navOverPlan"]
    assert_in_delta bottom["planTop"], bottom["schedulePhotoTop"], 3
    assert_in_delta bottom["planBottom"], bottom["rsvpPhotoTop"], 3
    assert_in_delta bottom["viewportHeight"] / 3.0, bottom["rsvpPhotoTop"], 3
    assert_operator bottom["rsvpPhotoHeight"], :>=,
      bottom["viewportHeight"] * 2.0 / 3.0 - 3
    assert_operator bottom["rsvpPhotoBottom"], :>=,
      bottom["viewportHeight"] - 3
    assert_in_delta 0, bottom["rsvpObjectY"], 0.01
  end

  test "image layers visibly lag behind their sections while scrolling" do
    page.current_window.resize_to(1440, 900)
    visit invitation_path(@invitation.access_token)

    before = motion_metrics
    layout = panel_metrics
    scroll_target = layout["heroHeight"] * 0.95
    capture("invitation-desktop-motion-start")
    page.execute_script(<<~JAVASCRIPT, scroll_target)
      document.documentElement.style.scrollBehavior = "auto"
      window.scrollTo(0, arguments[0])
    JAVASCRIPT

    Selenium::WebDriver::Wait.new(timeout: 2).until do
      motion_metrics["heroOffset"] > before["heroOffset"] + 100
    end

    after = motion_metrics
    capture("invitation-desktop-motion-after")
    assert_operator after["heroOffset"] - before["heroOffset"], :>, 100
    assert_operator (after["heroPhotoTop"] - before["heroPhotoTop"]).abs,
      :<, (after["heroPanelTop"] - before["heroPanelTop"]).abs
    assert_operator after["scheduleOffset"] - before["scheduleOffset"],
      :>, layout["planHeight"] * 0.18
  end

  private

  def emulate_phone(width:, height:)
    page.driver.browser.execute_cdp(
      "Emulation.setDeviceMetricsOverride",
      width: width,
      height: height,
      deviceScaleFactor: 1,
      mobile: true
    )
  end

  def clear_phone_emulation
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
  rescue Selenium::WebDriver::Error::WebDriverError
    nil
  end

  def assert_element_inside_viewport(selector)
    bounds = page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const rect = document.querySelector(#{selector.to_json}).getBoundingClientRect()
        return { left: rect.left, right: rect.right, width: window.innerWidth }
      })()
    JAVASCRIPT

    assert_operator bounds["left"], :>=, 0
    assert_operator bounds["right"], :<=, bounds["width"]
  end

  def panel_metrics
    page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const hero = document.querySelector(".hero-panel").getBoundingClientRect()
        const plan = document.querySelector(".schedule-panel").getBoundingClientRect()
        const rsvp = document.querySelector(".rsvp-panel").getBoundingClientRect()
        const rsvpForm = document.querySelector(".rsvp-panel__form-wrap").getBoundingClientRect()
        const schedulePhoto = document.querySelector(".schedule-panel__photo").getBoundingClientRect()
        const scheduleImageStyle = getComputedStyle(document.querySelector(".schedule-panel__photo img"))
        const rsvpPhoto = document.querySelector(".rsvp-panel__photo").getBoundingClientRect()
        const rsvpImageStyle = getComputedStyle(document.querySelector(".rsvp-panel__photo img"))
        const nav = document.querySelector(".invitation-nav").getBoundingClientRect()
        const navStyle = getComputedStyle(document.querySelector(".invitation-nav"))
        const navLayers = document.elementsFromPoint(window.innerWidth / 2, nav.height / 2)
        const upperPoint = document.elementFromPoint(12, Math.max(nav.bottom + 8, plan.top + 8))
        const lowerPoint = document.elementFromPoint(12, Math.min(window.innerHeight - 8, plan.bottom + 8))

        return {
          viewportHeight: window.innerHeight,
          heroHeight: hero.height,
          heroBottom: hero.bottom,
          planTop: plan.top,
          planHeight: plan.height,
          planBottom: plan.bottom,
          rsvpTop: rsvp.top,
          rsvpFormTop: rsvpForm.top,
          rsvpBottom: rsvp.bottom,
          schedulePhotoTop: schedulePhoto.top,
          schedulePhotoBottom: schedulePhoto.bottom,
          schedulePhotoHeight: schedulePhoto.height,
          scheduleObjectY: Number.parseFloat(scheduleImageStyle.objectPosition.split(/\s+/)[1]),
          rsvpPhotoTop: rsvpPhoto.top,
          rsvpPhotoBottom: rsvpPhoto.bottom,
          rsvpPhotoHeight: rsvpPhoto.height,
          rsvpObjectY: Number.parseFloat(rsvpImageStyle.objectPosition.split(/\s+/)[1]),
          navBackgroundColor: navStyle.backgroundColor,
          navBackgroundImage: navStyle.backgroundImage,
          navOverHero: navLayers.some((element) => element.closest?.(".hero-panel")),
          navOverPlan: navLayers.some((element) => element.closest?.(".schedule-panel")),
          planPosition: getComputedStyle(document.querySelector(".schedule-panel")).position,
          upperShowsPlan: Boolean(upperPoint?.closest(".schedule-panel")),
          lowerShowsRsvp: Boolean(lowerPoint?.closest(".rsvp-panel"))
        }
      })()
    JAVASCRIPT
  end

  def motion_metrics
    page.evaluate_script(<<~JAVASCRIPT)
      (() => {
        const heroPanel = document.querySelector(".hero-panel").getBoundingClientRect()
        const heroPhoto = document.querySelector(".hero-panel__photo").getBoundingClientRect()
        const schedulePhoto = document.querySelector(".schedule-panel__photo")

        return {
          heroPanelTop: heroPanel.top,
          heroPhotoTop: heroPhoto.top,
          heroOffset: Number.parseFloat(getComputedStyle(document.querySelector(".hero-panel__photo")).getPropertyValue("--parallax-y")) || 0,
          scheduleOffset: Number.parseFloat(getComputedStyle(schedulePhoto).getPropertyValue("--parallax-y")) || 0
        }
      })()
    JAVASCRIPT
  end

  def scroll_to_section(selector)
    page.execute_script(<<~JAVASCRIPT)
      document.documentElement.style.scrollBehavior = "auto"
      document.querySelector(#{selector.to_json}).scrollIntoView()
    JAVASCRIPT
  end

  def capture(name)
    return unless ENV["CAPTURE_SCREENSHOTS"] == "1"

    page.driver.browser.save_screenshot(Rails.root.join("tmp/screenshots/#{name}.png").to_s)
  end
end
