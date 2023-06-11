const CellularAutomaton = @import("../generation/cellular-automaton.zig").CellularAutomaton;

// The size of a map chunk in cells.
pub const MAP_CHUNK_SIZE = 100;

// The default map chunk automaton
pub const MapAutomaton = CellularAutomaton(MAP_CHUNK_SIZE, MAP_CHUNK_SIZE);
pub const automaton = MapAutomaton.init();
