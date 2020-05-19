package hxblit;

/**
 * ...
 * @author ...
 */
class Utils {
	static public function nbpo2(_in:Int):Int {
		_in--;
		_in = (_in >> 1) | _in;
		_in = (_in >> 2) | _in;
		_in = (_in >> 4) | _in;
		_in = (_in >> 8) | _in;
		_in = (_in >> 16) | _in;
		_in++;

		return _in;
	}
}
