module cache;

import logger;

import core.time;
import std.container.dlist;
import std.range;
import std.typecons;

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

    abstract V initialize(K key);
    bool needUpdate(const(K) key, const(V) value)
    {
        return false;
    }

    V get(K key)
    {
        auto p = key in impl;
        V val;

        if (p is null || needUpdate(key, *p))
        {
            val = initialize(key);
            if (val !is null)
            {
                impl[key] = val;
            }
        }
        else
        {
            val = *p;
        }
        debug(wlog) trace("Cache: get null = ", val is null);
        return val;
    }

    void set(const(K) key, V value)
    {
        impl[key] = value;
    }
}

class LRUCache(K, V)
{
    private uint _capacity;
    struct Meta
    {
        K key;
        MonoTime ts;
    }
    private alias MetaList = DList!Meta;
    struct Stored
    {
        V value;
        MetaList.Range r;
    }
    private MetaList _meta_list;
    private Stored[K] _storage;
    this(uint capacity)
    {
        _capacity = capacity;
    }

    private V update(Stored* stored)
    {
        auto lr = stored.r;
        assert(!lr.empty());
        _meta_list.linearRemove(lr.take(1));
        auto meta = lr.front();
        meta.ts = MonoTime.currTime();
        _meta_list.insertFront(meta);
        stored.r = _meta_list[];
        return stored.value;
    }

    public Tuple!(V, bool) get(K key)
    {
        auto it = key in _storage;
        return it is null ? tuple(V.init, false) : tuple(update(it), true);
    }

    public Tuple!(K, V, MonoTime) recent()
    {
        auto meta = _meta_list.front();
        return tuple(meta.key, _storage[meta.key].value, meta.ts);
    }

    private void put(K key, V value)
    {
        _meta_list.insertFront(Meta(key, MonoTime.currTime()));
        _storage[key] = Stored(value, _meta_list[]);
    }

    public void set(K key, V value)
    {
        auto it = key in _storage;
        if (it !is null)
        {
            it.value = value;
            update(it);
            return;
        }
        if (_storage.length == _capacity)
        {
            auto meta = _meta_list.back();
            _storage.remove(meta.key);
            _meta_list.removeBack();
        }

        put(key, value);

    }
}

unittest
{
    auto cache = new LRUCache!(int, int)(3);
    auto res = cache.get(0);
    assert(res[1] == false);
    cache.set(0, 10);
    res = cache.get(0);
    assert(res[0] == 10);
    assert(res[1] == true);
    cache.set(1, 20);
    cache.set(2, 30);
    assert(cache.recent()[1] == 30);
    cache.set(3, 40);
    res = cache.get(0);
    assert(res[1] == false);
    cache.set(4, 50);
    cache.set(5, 60);
    res = cache.get(2);
    assert(res[1] == false);
    res = cache.get(3);
    assert(res[1] == true);
    assert(res[0] == 40);
    cache.set(6, 70);
    res = cache.get(4);
    assert(res[1] == false);
}
