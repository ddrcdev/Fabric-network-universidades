/*
 * Copyright IBM Corp. All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const adminStudent = require('./lib/adminStudent');

module.exports.adminStudent = adminStudent;
module.exports.contracts = [adminStudent];
