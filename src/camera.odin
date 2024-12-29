package game

import rl "vendor:raylib"

camera_yaw :: proc(camera: ^rl.Camera, angle: f32) {
    if angle == 0 do return

    target := camera.target - camera.position
    target = rl.Vector3RotateByAxisAngle(target, camera.up, angle)

    camera.target = camera.position + target
}

camera_pitch :: proc(camera: ^rl.Camera, angle: f32) {
    if angle == 0 do return

    target := camera.target - camera.position

    forward := rl.Vector3Normalize(target)
    up := rl.Vector3Normalize(camera.up)
    right := rl.Vector3CrossProduct(forward, up)

    minAngleUp := -rl.Vector3Angle(-up, target) + 0.001
    maxAngleUp := rl.Vector3Angle(up, target) - 0.001
    clampedAngle := clamp(angle, minAngleUp, maxAngleUp)

    target = rl.Vector3RotateByAxisAngle(target, right, clampedAngle)

    camera.target = camera.position + target
}
