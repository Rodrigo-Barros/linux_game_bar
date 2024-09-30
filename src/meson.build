project('linux game bar','vala','c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('libpulse'),
    dependency('libpulse-mainloop-glib'),
    dependency('gee-0.8'),
    dependency('sdl2'),
    dependency('gtk+-3.0'),
    dependency('json-glib-1.0'),
    dependency('gio-2.0')
]

sources = [
    files('app.vala'),
    files('modules/joystick.vala'),
    files('modules/pulse_audio.vala'),
    files('modules/window.vala'),
    files('modules/settings.vala'),
    files('modules/media_player.vala'),
    files('modules/action.vala')
]

executable('linux_game_bar', sources, dependencies: dependencies)
