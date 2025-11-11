class_name SeaWave extends Node3D

enum WaveType {
	SMALL,
	MEDIUM,
	LARGE,
}

@export var wave_type: WaveType = WaveType.SMALL
@export var wave_size: int = 10