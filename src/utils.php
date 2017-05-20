<?php

namespace TestMe;

class Utils
{
    /**
     * Something fixed.
     *
     * @const string
     */
    const SOMETHING_FIXED = 'abcdefg';

    /**
     * Does something.
     *
     * @return string
     */
    public static function doSomething()
    {
        return self::SOMETHING_FIXED;
    }
}