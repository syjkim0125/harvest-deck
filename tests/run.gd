extends SceneTree

const SawAudio = preload("res://scripts/saw_audio.gd")
const Game = preload("res://scripts/game.gd")
const Production = preload("res://scripts/production.gd")
const Impact = preload("res://scripts/impact.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
	print("PASS " if ok else "FAIL ", label)

func fixture(game, hp: int = 3) -> void:
	game.fruits.clear()
	game.cargo.clear()
	game.player = Vector2(700, 700)
	game.facing = Vector2.RIGHT
	game.fruits.append({"pos": Vector2(755, 700), "home": Vector2(755, 700), "hp": hp, "kind": 0, "flash": 0.0, "respawn": 0.0, "freeze": 0.0})
	game.impact.clear()

func run() -> void:
	var g = Game.new()
	root.add_child(g)
	g.set_physics_process(false)
	g.sound_on = false
	fixture(g)
	g.facing = Vector2.LEFT
	check(g.attack() == 0 and g.impact.trauma == 0, "whiff has no damage or shake")
	g.facing = Vector2.RIGHT
	check(g.attack() == 1 and g.fruits[0].hp == 2 and g.impact.trauma > 0, "each confirmed hit produces feedback")
	g.attack()
	g.attack()
	check(g.cargo.size() == 3 and g.fruits[0].hp == 0, "kill awards three items")
	check(g.attack() == 0 and g.cargo.size() == 3, "dead target cannot duplicate drops")
	fixture(g, 1)
	g.cargo.resize(39)
	g.cargo.fill(0)
	g.attack()
	check(g.cargo.size() == 40 and g.ground_drops.size() == 2, "capacity overflow stays on ground; no reward loss")
	var hp = g.fruits[0].hp
	check(g.attack() == 0 and g.fruits[0].hp == hp, "full bag prevents cutting")
	fixture(g)
	g.fruits.append(g.fruits[0].duplicate(true))
	check(g.attack() == 2, "one pulse can cut multiple targets")
	for i in range(100):
		g.impact.hit()
	check(g.impact.trauma <= 1.0 and g.impact.step(0.0).length() <= Impact.MAX_PIXELS, "crowd impact saturates")
	# Dense simultaneous impacts must equal one pulse, with a hard short lifetime.
	var single = Impact.new()
	var crowd = Impact.new()
	single.hit(true)
	for i in range(100):
		crowd.hit(true)
	check(single.step(0.01).is_equal_approx(crowd.step(0.01)), "crowd does not amplify or extend pulse")
	for rate in [30, 60, 120]:
		var short_fx = Impact.new()
		short_fx.hit(true)
		var peak = 0.0
		for frame in range(ceili(Impact.DURATION * rate) + 1):
			peak = maxf(peak, short_fx.step(1.0 / rate).length())
		check(peak <= Impact.MAX_PIXELS and short_fx.trauma == 0.0, "pulse ends within 100ms at %dfps" % rate)
	# Verify rendered offsets, since a nonzero envelope alone can still be imperceptible.
	for rate in [30, 60, 120]:
		var visible_fx = Impact.new()
		visible_fx.hit()
		var visible_peak = 0.0
		for frame in range(ceili(Impact.DURATION * rate)):
			visible_peak = maxf(visible_peak, visible_fx.step(1.0 / rate).length())
		check(visible_peak >= 3.0 and visible_peak <= Impact.MAX_PIXELS, "normal hit has visible bounded displacement at %dfps" % rate)
	var comfy = Impact.new()
	comfy.reduced = true
	comfy.hit(true)
	check(comfy.trauma == 0.0 and comfy.step(0.001) == Vector2.ZERO, "no-shake mode does not retain a hidden pulse")
	check(Game.SPEED == 360.0, "faster movement is the default")
	for fps in [30, 60, 120]:
		var fx = Impact.new()
		fx.hit(true)
		for i in range(fps):
			fx.step(1.0 / fps)
		check(is_zero_approx(fx.trauma), "shake returns to zero at %dfps" % fps)
		fixture(g)
		g.fruits.clear()
		var start: Vector2 = g.player
		for i in range(fps):
			g.simulate(1.0 / fps, Vector2.RIGHT)
		check(absf(g.player.x - start.x - Game.SPEED) < 0.02, "movement speed at %dfps" % fps)
	fixture(g)
	g.impact.reduced = true
	g.attack()
	check(g.impact.step(0.01) == Vector2.ZERO and g.fruits[0].hp == 2, "reduced motion preserves damage")
	g.impact.reduced = false
	g.set_paused(true)
	check(g.impact.trauma == 0 and g.camera.offset == Vector2.ZERO and g.drag_id == -1, "pause clears impact and touch")
	g.reset_run()
	g.fruits.clear()
	g.cargo.assign([0, 1, 0])
	g.player = g.depot
	for i in range(180):
		g.simulate(1.0 / 60.0, Vector2.ZERO)
	check(g.cargo.is_empty() and g.stock == 3 and g.production.pending_cash == 0, "unattended depot produces but does not sell")
	g.player = g.service_pad
	for i in range(150):
		g.simulate(1.0 / 60.0, Vector2.ZERO)
	check(g.stock == 0 and g.production.pending_cash == 15 and g.cash == 0, "attended counter serves customers and preserves items")
	g.player = g.cash_pad
	g.simulate(0.01, Vector2.ZERO)
	check(g.cash == 15 and g.production.pending_cash == 0, "cash collected only at gold pad")
	g.simulate(0.01, Vector2.ZERO)
	check(g.cash == 15, "cash cannot be collected twice")
	g.camera.offset = Vector2(4, 7)
	g.reset_run()
	check(g.camera.offset == Vector2.ZERO and g.camera.position == g.player, "reset snaps camera and clears stale shake")
	check(g.cargo.is_empty() and g.cash == 0 and g.stock == 0 and g.hits == 0 and g.impact.trauma == 0, "reset clears run state")
	fixture(g)
	g.local_stop = true
	g.attack()
	check(g.fruits[0].freeze > 0 and Engine.time_scale == 1.0, "local stop does not slow simulation clock")
	# Real fixture for overflow pickup after returning from the depot.
	g.reset_run()
	fixture(g, 1)
	g.cargo.resize(39)
	g.cargo.fill(0)
	g.attack()
	var drops = g.ground_drops.size()
	g.cargo.clear()
	g.player = g.fruits[0].pos
	g.simulate(0.001, Vector2.ZERO)
	check(drops == 2 and g.ground_drops.is_empty() and g.cargo.size() == 2, "overflow can be recovered without duplicate kill")
	# Sound must not advance the gameplay RNG (particles, respawn experiments).
	g.reset_run()
	fixture(g)
	g.sound_on = false
	g.attack()
	var silent_rng = g.rng.state
	g.reset_run()
	fixture(g)
	g.sound_on = true
	# Headless Dummy audio playback leaks engine WAV playback objects on exit.
	# Exercise pitch RNG without claiming a real output-device listening test.
	var output_player = g.audio
	g.audio = null
	g.attack()
	g.audio = output_player
	check(g.rng.state == silent_rng, "sound toggle preserves seeded gameplay RNG")
	g.set_paused(true)
	var snapshot = [g.player, g.time, g.production.inventory_count(), g.hits, g.camera.position]
	g._physics_process(1.0)
	check(snapshot == [g.player, g.time, g.production.inventory_count(), g.hits, g.camera.position], "pause freezes movement, harvest and production")
	g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(g.paused and g.drag_id == -1, "focus-out pauses and releases touch")
	var factory = Production.new()
	factory.deposit(1)
	factory.step(0.2)
	check(factory.active_kind == 1 and factory.raw.is_empty() and factory.ready.is_empty(), "raw enters mixer without selling early")
	factory.step(0.25)
	check(factory.active_kind == -1 and factory.ready == [1] and factory.pending_cash == 0, "completed item retains fruit kind")
	factory.step(0.7)
	check(factory.sold_by_kind == [0, 1] and factory.pending_cash == 5, "only completed products can sell")
	var summaries = []
	for fps in [30, 60, 120]:
		var line = Production.new()
		for k in [0, 1, 1, 0, 1, 0]:
			line.deposit(k)
		for i in range(fps * 6):
			line.step(1.0 / fps)
		summaries.append([line.inventory_count(), line.sold_by_kind.duplicate(), line.pending_cash])
	check(summaries[0] == summaries[1] and summaries[1] == summaries[2] and summaries[0] == [0, [3, 3], 30], "production and sales agree at 30 / 60 / 120 fps")
	factory.reset()
	for k in [0, 1, 1, 0, 1, 0]:
		factory.deposit(k)
	factory.step(6.0)
	check([factory.inventory_count(), factory.sold_by_kind, factory.pending_cash] == summaries[0], "large step respects chronological processing and sales")
	factory.collect()
	check(factory.collect() == 0 and factory.collected_cash == 30, "production cash collection is idempotent")
	factory.reset()
	check(factory.inventory_count() == 0 and factory.pending_cash == 0 and factory.collected_cash == 0 and factory.sold_by_kind == [0, 0], "production reset clears every resource stage")
	# Feedback must only affect presentation, never target collision coordinates.
	g.reset_run()
	fixture(g)
	g.sound_on = false
	var original: Vector2 = g.fruits[0].pos
	g.feedback = true
	g.attack()
	check(g.fruits[0].pos == original and g.fruits[0].recoil.length() > 0, "hit recoil does not move gameplay collision target")
	g.impact.step(0.123)
	g.reset_run()
	check(g.impact.clock == 0.0, "reset also resets shake phase for repeatable comparisons")
	var shop = Production.new()
	shop.deposit(0)
	shop.step(1.0, false)
	check(shop.sold_by_kind == [0, 0] and shop.ready == [0] and shop.customers.size() == 3, "unattended queue waits without consuming product")
	shop.step(0.3, true)
	var progress: float = shop.sale_elapsed
	shop.step(0.2, false)
	check(is_equal_approx(shop.sale_elapsed, progress), "leaving counter preserves partial service progress")
	shop.step(0.4, true)
	check(shop.served_ids == [1] and shop.pending_cash == 5 and shop.ready.is_empty(), "first waiting customer receives exactly one product")
	shop.step(10.0, true)
	check(shop.served_ids == [1] and shop.pending_cash == 5 and shop.customers.size() == Production.MAX_QUEUE, "stockout cannot create phantom sales; queue is bounded")
	shop.deposit(1)
	shop.step(1.2, true)
	check(shop.served_ids == [1, 2] and shop.sold_by_kind == [1, 1], "FIFO queue advances and consumes matching inventory kind")
	shop.reset()
	check(shop.served_ids.is_empty() and shop.customers[0].id == 1 and shop.sale_elapsed == 0 and shop.arrival_elapsed == 0, "reset clears customers, identifiers and service clocks")
	var queue_summaries = []
	for fps in [30, 60, 120]:
		var line = Production.new()
		for i in range(20):
			line.deposit(i % 2)
		for i in range(12 * fps):
			line.step(1.0 / fps, true)
		queue_summaries.append([line.inventory_count(), line.pending_cash, line.served_ids.duplicate(), line.customers.duplicate(true)])
	check(queue_summaries[0] == queue_summaries[1] and queue_summaries[1] == queue_summaries[2], "arrivals / service / stock agree at 30, 60 and 120 Hz")
	shop.reset()
	for i in range(20):
		shop.deposit(i % 2)
	shop.step(12.0, true)
	check([shop.inventory_count(), shop.pending_cash, shop.served_ids, shop.customers] == queue_summaries[0], "large-delta customer arrivals remain chronological")
	g.player = g.service_pad
	var screen_y: float = 135.0 - g.camera_follow_target().y + 360.0
	check(screen_y > g.HUD_HEIGHT + 34, "counter camera keeps customer heads below fixed HUD")
	g.player = g.service_pad + Vector2(0, 64)
	screen_y = 135.0 - g.camera_follow_target().y + 360.0
	check(screen_y > g.HUD_HEIGHT + 34, "customer heads stay below HUD at outer service radius")
	# Audio envelopes and source PCM are checked without pretending to hear a device.
	g.reset_run()
	fixture(g)
	g.set_sound_enabled(true)
	g.facing = Vector2.LEFT
	g.attack()
	check(g.saw_audio.contact_left == 0, "whiff never triggers cutting sound layer")
	g.facing = Vector2.RIGHT
	g.attack()
	check(g.saw_audio.contact_left == SawAudio.CONTACT_HOLD, "confirmed hit opens bounded contact envelope")
	g.saw_audio.step(0.02, true, true, false)
	check(g.saw_audio.cut_gain > 0 and g.saw_audio.mode() == "CUT", "contact layer rises only after confirmed contact")
	g.set_sound_enabled(false)
	check(g.saw_audio.cut_gain == 0 and g.saw_audio.motor_gain == 0 and g.saw_audio.contact_left == 0, "sound OFF clears all layers and stale contact")
	g.set_sound_enabled(true)
	g.saw_audio.step(0.02, true, false, false)
	check(g.saw_audio.cut_gain == 0 and g.saw_audio.mode() == "IDLE", "unmute resumes idle, not a stale cut")
	g.saw_audio.confirmed_hit()
	g.saw_audio.step(0.02, true, false, false)
	g.set_paused(true)
	check(g.saw_audio.mode() == "OFF" and g.saw_audio.contact_left == 0, "pause silences motor and contact layer immediately")
	g.saw_audio.confirmed_hit()
	g.reset_run()
	check(g.saw_audio.contact_left == 0 and g.saw_audio.mode() == "OFF", "reset clears audio state")
	g.saw_audio.confirmed_hit()
	g._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(g.saw_audio.contact_left == 0 and g.saw_audio.mode() == "OFF", "focus-out silences all saw layers")
	g.reset_run()
	g.saw_audio.confirmed_hit()
	g.saw_audio.step(0.6, true, false, false)
	check(g.saw_audio.cut_gain < 0.0001, "lost contact decays to silence without a stuck cutting loop")
	g.saw_audio.confirmed_hit()
	g.saw_audio.step(0.1, true, false, true)
	check(g.saw_audio.contact_left == 0, "full cargo cannot sustain a cutting sound")
	var gains = []
	for fps in [30, 60, 120]:
		g.saw_audio.silence()
		g.saw_audio.confirmed_hit()
		for i in range(fps / 2):
			g.saw_audio.step(1.0 / fps, true, true, false)
		gains.append(g.saw_audio.cut_gain)
	check(absf(gains[0] - gains[1]) < 0.00001 and absf(gains[1] - gains[2]) < 0.00001, "contact envelope agrees at 30 / 60 / 120 Hz")
	g.saw_audio.master_gain = 1.0
	for i in range(120):
		g.saw_audio.confirmed_hit()
		g.saw_audio.step(1.0 / 120, true, true, false)
	check(g.saw_audio.cut_gain <= 0.28 and g.saw_audio.motor_gain <= 0.20, "dense hits cannot stack unbounded audio gain")
	g.saw_audio.master_gain = 0.0
	g.saw_audio.step(0.01, true, true, false)
	check(g.saw_audio.mode() == "OFF", "zero volume shuts down loop state")
	for cutting in [false, true]:
		var wave = SawAudio.make_loop(cutting)
		var pcm: PackedByteArray = wave.data
		var peak = 0
		var max_step = 0
		for i in range(SawAudio.SAMPLES):
			var sample = pcm.decode_s16(i * 2)
			peak = maxi(peak, absi(sample))
			if i > 0:
				max_step = maxi(max_step, absi(sample - pcm.decode_s16((i - 1) * 2)))
		var seam = absi(pcm.decode_s16(0) - pcm.decode_s16((SawAudio.SAMPLES - 1) * 2))
		check(wave.loop_mode == AudioStreamWAV.LOOP_FORWARD and wave.loop_end == SawAudio.SAMPLES and pcm.size() == SawAudio.SAMPLES * 2 and peak < 32767, "synthesized %s loop has bounded valid PCM" % str(cutting))
		check(seam <= max_step, "synthesized %s loop seam stays within waveform slope" % str(cutting))
	check(g.audio.max_polyphony == 2, "hit voice overlap is capped at two")
	var peaks: Array[float] = []
	for wave in [SawAudio.make_loop(false), SawAudio.make_loop(true), g.audio.stream]:
		var pcm: PackedByteArray = wave.data
		var peak: float = 0
		for i in range(pcm.size() / 2):
			peak = maxf(peak, absf(pcm.decode_s16(i * 2) / 32767.0))
		peaks.append(peak)
	check(peaks[0] * 0.20 + peaks[1] * 0.28 + peaks[2] * 2 * 0.75 < 1.0, "maximum loop gains plus two hit voices stay below PCM clipping bound")
	var staffing = Production.new()
	staffing.pending_cash = Production.CASHIER_COST
	check(not staffing.hire_cashier() and not staffing.cashier_hired and staffing.pending_cash == 30, "uncollected counter cash cannot pay a cashier")
	staffing.collect()
	check(staffing.hire_cashier() and staffing.collected_cash == 0 and staffing.spent_cash == 30, "cashier hire atomically spends collected cash")
	check(not staffing.hire_cashier() and staffing.spent_cash == 30, "duplicate hire cannot spend again")
	staffing.deposit(1)
	staffing.step(1.2, false)
	check(staffing.pending_cash == 5 and staffing.served_total == 1 and staffing.inventory_count() == 0, "hired cashier serves without the player")
	staffing.step(5.0, false)
	check(staffing.pending_cash == 5 and staffing.served_total == 1, "cashier cannot sell nonexistent stock")
	staffing.reset()
	check(not staffing.cashier_hired and staffing.spent_cash == 0 and staffing.served_total == 0, "reset removes worker, spending and service history")
	var staffing_results = []
	for operator in [false, true]:
		var line = Production.new()
		line.collected_cash = 30
		line.hire_cashier()
		for i in range(6):
			line.deposit(i % 2)
		line.step(6.0, operator)
		staffing_results.append([line.sold_by_kind, line.pending_cash, line.inventory_count()])
	check(staffing_results[0] == staffing_results[1] and staffing_results[0] == [[3, 3], 30, 0], "player plus cashier does not double the service rate")
	staffing.collected_cash = 30
	staffing.hire_cashier()
	for i in range(300):
		staffing.deposit(i % 2)
	staffing.step(600.0, false)
	check(staffing.served_total == 300 and staffing.served_ids.size() == Production.MAX_SERVED_HISTORY and staffing.served_ids[-1] == 300, "long automatic service bounds history without losing total sales")
	check(staffing.inventory_count() == 0 and staffing.pending_cash == 1500 and staffing.sold_by_kind == [150, 150], "long automatic service preserves kinds and cash")
	g.reset_run()
	g.production.collected_cash = 30
	g.player = g.hire_pad
	g.set_paused(true)
	check(not g.try_hire_cashier() and g.cash == 30, "pause blocks hiring")
	g.set_paused(false)
	g.player = g.depot
	check(not g.try_hire_cashier() and g.cash == 30, "hiring requires proximity to purple pad")
	g.player = g.hire_pad
	check(g.try_hire_cashier() and g.cash == 0 and g.production.cashier_hired, "world hire interaction buys worker at purple pad")
	check(not g.try_hire_cashier() and g.cash == 0, "repeated world interaction is idempotent")
	g.fruits.clear()
	g.production.deposit(0)
	g.player = Vector2(700, 720)
	for i in range(120):
		g.simulate(1.0 / 60, Vector2.ZERO)
	check(g.production.pending_cash == 5 and g.player.distance_to(g.service_pad) > 65, "game loop connects cashier to unattended sales")
	g.set_paused(true)
	var before_pending: int = g.production.pending_cash
	g._physics_process(3.0)
	check(g.production.pending_cash == before_pending and g.hire_button.disabled, "pause stops automatic staff and disables hire control")
	g.reset_run()
	var touch = InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	touch.position = Vector2(800, 90)
	g._input(touch)
	check(g.drag_id == -1, "raw input does not start movement before UI consumes touch")
	g._unhandled_input(touch)
	check(g.drag_id == 7, "unhandled gameplay touch still starts movement drag")
	touch.pressed = false
	g.drag_vector = Vector2.RIGHT
	g._input(touch)
	check(g.drag_id == -1 and g.drag_vector == Vector2.ZERO, "touch release clears drag even when a HUD control consumes the event")
	var facility = Production.new()
	facility.pending_cash = 40
	check(not facility.upgrade_mixer() and not facility.mixer_upgraded and facility.pending_cash == 40, "uncollected money cannot fund mixer upgrade")
	facility.collect()
	facility.deposit(1)
	facility.step(0.225, false)
	var fraction: float = facility.mix_elapsed / facility.mix_duration()
	check(facility.upgrade_mixer() and facility.collected_cash == 0 and facility.spent_cash == 40, "mixer upgrade spends wallet exactly once")
	check(is_equal_approx(facility.mix_elapsed / facility.mix_duration(), fraction) and facility.active_kind == 1 and facility.inventory_count() == 1, "upgrade preserves active job fraction, kind and item count")
	check(not facility.upgrade_mixer() and facility.spent_cash == 40, "duplicate mixer upgrade cannot spend money")
	facility.step(0.124, false)
	check(facility.ready.is_empty(), "upgrade does not instantly complete unfinished work")
	facility.step(0.001, false)
	check(facility.ready == [1] and facility.inventory_count() == 1, "upgraded in-flight job completes at preserved remaining fraction")
	var throughput = []
	for upgraded in [false, true]:
		var line = Production.new()
		if upgraded:
			line.collected_cash = 40
			line.upgrade_mixer()
		for i in range(10):
			line.deposit(i % 2)
		line.step(2.0, false)
		throughput.append(line.ready.size())
		check(line.inventory_count() == 10 and line.sold_by_kind == [0, 0], "mixer processing conserves ten deposited items (%s)" % str(upgraded))
	check(throughput == [4, 8], "same two seconds produces four base or eight upgraded items")
	var upgraded_summaries = []
	for fps in [30, 60, 120]:
		var line = Production.new()
		line.collected_cash = 40
		line.upgrade_mixer()
		for i in range(10):
			line.deposit(i % 2)
		for i in range(fps * 2):
			line.step(1.0 / fps, false)
		upgraded_summaries.append([line.ready.duplicate(), line.raw.duplicate(), line.active_kind])
	check(upgraded_summaries[0] == upgraded_summaries[1] and upgraded_summaries[1] == upgraded_summaries[2], "upgraded processing agrees at 30 / 60 / 120 Hz")
	facility.reset()
	check(not facility.mixer_upgraded and facility.mix_duration() == Production.MIX_SECONDS and facility.spent_cash == 0, "reset restores base facility and clears upgrade spending")
	facility.collected_cash = 70
	facility.hire_cashier()
	facility.upgrade_mixer()
	for i in range(6):
		facility.deposit(i % 2)
	facility.step(6.0, false)
	facility.collect()
	check(facility.collected_cash == 30 and facility.spent_cash == 70 and facility.inventory_count() == 0 and facility.sold_by_kind == [3, 3], "cashier plus upgrade preserve spending, stock and automatic revenue")
	g.reset_run()
	g.production.collected_cash = 40
	g.player = g.upgrade_pad
	g.set_paused(true)
	check(not g.try_upgrade_mixer() and g.cash == 40, "pause prevents facility purchase")
	g.set_paused(false)
	g.player = g.depot
	check(not g.try_upgrade_mixer() and g.cash == 40, "facility purchase requires coral-pad proximity")
	g.player = g.upgrade_pad
	check(g.try_upgrade_mixer() and g.cash == 0 and g.production.mixer_upgraded, "world interaction upgrades mixer at coral pad")
	check(not g.try_upgrade_mixer() and g.cash == 0, "repeated world facility interaction cannot double charge")
	check(g.orchard_button.position.y >= g.status.position.y + g.status.get_minimum_size().y and g.orchard_button.position.y + g.orchard_button.size.y <= g.HUD_HEIGHT, "purchase controls sit below all status lines inside HUD")
	g.reset_run()
	fixture(g)
	g.fruits[0].kind = 1
	check(g.attack() == 0 and g.hits == 0 and g.impact.trauma == 0 and g.cargo.is_empty(), "locked orchard cannot create hits, shake or rewards")
	g.fruits[0].hp = 0
	g.fruits[0].respawn = 0.1
	g.simulate(0.2, Vector2.ZERO)
	check(g.fruits[0].hp == 0 and is_equal_approx(g.fruits[0].respawn, 0.1), "locked orchard does not run a hidden respawn clock")
	g.production.pending_cash = 50
	g.player = g.orchard_pad
	check(not g.try_unlock_orchard() and g.production.pending_cash == 50, "orchard cannot spend uncollected cash")
	g.production.collect()
	g.set_paused(true)
	check(not g.try_unlock_orchard() and g.cash == 50, "pause blocks orchard purchase")
	g.set_paused(false)
	g.player = g.depot
	check(not g.try_unlock_orchard() and g.cash == 50, "orchard purchase requires pad proximity")
	g.player = g.orchard_pad
	check(g.try_unlock_orchard() and g.cash == 0 and g.production.spent_cash == 50, "orchard unlock spends collected wallet once")
	check(not g.try_unlock_orchard() and g.production.spent_cash == 50, "duplicate orchard unlock does not charge twice")
	g.simulate(0.11, Vector2.ZERO)
	check(g.fruits[0].hp == 3, "unlocked dead fruit resumes normal respawn")
	g.player = Vector2(700, 700)
	g.facing = Vector2.RIGHT
	g.cooldown = 100
	for i in range(3):
		g.attack()
	check(g.cargo == [1, 1, 1], "unlocked orchard produces its own fruit kind")
	g.player = g.depot
	for i in range(120):
		g.simulate(1.0 / 60, Vector2.ZERO)
	check(g.cargo.is_empty() and g.production.ready == [1, 1, 1], "unlocked fruit survives delivery and processing without conversion")
	g.player = g.service_pad
	for i in range(180):
		g.simulate(1.0 / 60, Vector2.ZERO)
	g.player = g.cash_pad
	g.simulate(0.01, Vector2.ZERO)
	check(g.production.sold_by_kind == [0, 3] and g.cash == 15 and g.stock == 0, "unlocked fruit sells and collected money conserves its value")
	g.reset_run()
	check(not g.production.orchard_unlocked and g.cash == 0 and g.production.spent_cash == 0, "reset relocks orchard and clears spending")
	fixture(g)
	check(g.attack() == 1, "starter fruit remains harvestable after reset")
	var progression = Production.new()
	for i in range(12):
		progression.deposit(0)
	progression.step(20.0, true)
	progression.collect()
	check(progression.collected_cash == 60 and progression.unlock_orchard() and progression.collected_cash == 10 and progression.spent_cash == 50, "starter fruit sales can fund orchard without mixer or cashier prerequisite")
	# Cadence must not undercount on a long frame or repay old debt as a burst.
	for rate in [5, 30, 60, 120]:
		g.reset_run()
		fixture(g, 1000)
		g.sound_on = false
		for frame in range(rate * 2):
			g.simulate(1.0 / rate, Vector2.ZERO)
		check(g.hits == 20 and g.cooldown > 0.0, "two-second harvest cadence has twenty hits and no debt at %dHz" % rate)
	g.reset_run()
	fixture(g, 1000)
	g.simulate(0.5, Vector2.ZERO)
	var hitch_hits: int = g.hits
	g.simulate(1.0 / 120.0, Vector2.ZERO)
	check(hitch_hits == 5 and g.hits == hitch_hits, "half-second hitch resolves scheduled cuts without a next-frame burst")
	var path_outcomes = []
	for rate in [5, 30, 60, 120]:
		g.reset_run()
		fixture(g, 1000)
		g.player = Vector2(400, 700)
		g.fruits[0].pos = Vector2(550, 700)
		g.fruits[0].home = Vector2(550, 700)
		for frame in range(rate):
			g.simulate(1.0 / rate, Vector2.RIGHT)
		path_outcomes.append([g.hits, roundi(g.player.x), g.production.inventory_count(), g.cargo.size()])
	check(path_outcomes[0] == path_outcomes[1] and path_outcomes[1] == path_outcomes[2] and path_outcomes[2] == path_outcomes[3] and path_outcomes[0][0] > 0, "moving through a target agrees at 5 / 30 / 60 / 120Hz")
	g.reset_run()
	fixture(g, 1000)
	g.facing = Vector2.LEFT
	g.simulate(0.5, Vector2.ZERO)
	check(g.hits == 0 and g.impact.trauma == 0.0, "long-frame whiffs do not create feedback")
	g.set_paused(true)
	g.audio.stop()
	g.queue_free()
	await process_frame
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
