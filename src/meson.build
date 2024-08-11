project('linux game bar','vala','c')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
    dependency('libpulse'),
    dependency('libpulse-mainloop-glib'),
    dependency('gee-0.8'),
    dependency('sdl2')
]

sources = [
    files('app.vala'),
    files('modules/joystick.vala'),
    files('modules/pulse_audio.vala'),
]

executable('linux_game_bar', sources, dependencies: dependencies)
