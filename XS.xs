#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <assert.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <float.h>

#include "table.h"
#include "pagerank.h"
typedef Table TableRef;

MODULE = Algorithm::PageRank::XS	PACKAGE = Algorithm::PageRank::XS
PROTOTYPES: DISABLE



TableRef *
pr_tableinit()
PREINIT:
	Table * result;
CODE:
	result = table_init();
        RETVAL = result;
OUTPUT:
        RETVAL

void
pr_tabledel(input_table)
	TableRef * input_table;
PREINIT:
	Table * table;
CODE:
	table = (Table *)input_table;
        table_delete(table);

SV *
pr_tablesize(input_table)
	TableRef * input_table;
PREINIT:
	Table * table;
CODE:
	table = (Table *)input_table;
	RETVAL = newSVuv(table_len(table));
OUTPUT:
	RETVAL

SV *
pr_tableadd(input_table, from, to)
	TableRef * input_table;
	unsigned int from;
	unsigned int to;
PREINIT:
	Table * table;
	Array * tmp;
CODE:
	table = (Table *)input_table;

	if ((tmp = table_get(table, to)) == NULL)
		table_add(table, to, array_init(from));
	else
		array_push(tmp, from);

	RETVAL = newSVuv(1);
OUTPUT:
	RETVAL

SV *
pr_pagerank(input_table, order, alpha, convergence, max_tries)
	TableRef * input_table;
	unsigned int order;
	float alpha;
	float convergence;
	int max_tries;
PREINIT:
	Table * table;
	AV * results;
	int i;
	Array * result;
INIT:
	results = (AV *)sv_2mortal((SV *)newAV());
CODE:
	table = (Table *) input_table;
	result = page_rank(table, order, alpha, convergence, max_tries);
	if (!result)
		return NULL;

	for (i = 0; i < array_len(result); i++)
		av_push(results, newSVnv(array_get(result, i)));

	array_delete(result);

	RETVAL = newRV((SV *)results);
OUTPUT:
	RETVAL
