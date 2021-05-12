<?php

return [
	'exception_handling' => [
		'value' => [
			'debug' => true,
			'handled_errors_types' => E_ALL & ~E_NOTICE & ~E_USER_NOTICE & ~E_STRICT & ~E_DEPRECATED & ~E_USER_DEPRECATED,
			'exception_errors_types' => 0,
			'ignore_silence' => false,
			'assertion_throws_exception' => false,
			'assertion_error_type' => 256,
			'log' => [
				'settings' => [
					'file' => 'bitrix/modules/php-error.log',
					'log_size' => 1048576,
				],
			],
		],
		'readonly' => false,
	],

	// раскоментировать для https-сайтов - нужно для редиректов bitrix на https
	'https_request' => ['value' => true, 'readonly' => false],
];
