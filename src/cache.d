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
    bool needUpdate(const(K) key, const(V) value)
    {
        return false;
    }

    V get(const(K) key)
    {
        auto p = key in impl;
        V val;

        if (p is null || needUpdate(key, *p))
        {
            val = impl[key] = initialize(key);
        }

        assert(val !is null);
        return val;
    }
}
