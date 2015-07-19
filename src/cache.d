module cache;

class LazyCache(K, V)
{
    private uint _capacity;

    @property auto capacity() const
    {
        return _capacity;
    }

    V[const(K)] impl;
    this(uint capacity)
    {
        _capacity = capacity;
    }

    abstract V initialize(const(K) key);

    V get(const(K) key)
    {
        auto p = key in impl;
        auto val = p is null ? initialize(key) : *p;
        if (val is null)
        {
            return null;
        }
        if (p is null)
        {
            impl[key] = val;
        }
        return val;
    }
}
