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
     * Something else fixed.
     *
     * @const string
     */
    const SOMETHING_ELSE_FIXED = '01010101';

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