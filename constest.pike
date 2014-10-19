#!/usr/local/bin/pike

mixed eval(string code)
{
	catch {return compile_string("mixed _(){return "+code+";}")()->_();};
}

//Compare two strings for "equality". They are considered equal
//if they represent the same result.
int compare(string output, string expected)
{
	if (!expected) return 0;
	sscanf(output, "(%*d) Result: %s", output); //Trim off Hilfe markers
	sscanf(expected, "(%*d) Result: %s", expected); //on both strings
	output = String.trim_all_whites(output);
	expected = String.trim_all_whites(expected);
	if (output == expected) return 0; //Identical strings clearly match. This will cover most cases.
	//See if output and expected both begin and end with the same data type marker.
	//We can check arrays, mappings, and multisets for equality more tolerantly.
	string otype = output[..1] + output[<1..];
	string etype = expected[..1] + expected[<1..];
	if (otype == etype && (<"({})", "([])", "(<>)">)[otype])
	{
		//CAUTION: Compiling it up like this is a bad idea. What I really
		//want is something like Python's ast.literal_eval(), I think.
		array|mapping|multiset o = eval(output);
		array|mapping|multiset e = eval(expected);
		if (equal(o, e)) return 0;
	}
	write("FAIL\nExpected:\n%s\nOutput:\n%s\nTEST FAILED\n", expected, output);
	return 1;
}

int run_tests(string fn)
{
	program pgm = (program)fn;
	object obj = pgm();
	int testspassed;
	write("Testing %s\n", fn);
	foreach (indices(pgm), string name) if (has_prefix(name, "test") && stringp(pgm[name]))
	{
		write("Running %s... ",name);
		//Initialize a new Hilfe instance for each test string, but don't reinitialize
		//within one set of tests. This allows them to build on each other.
		object hilfe = Tools.Hilfe.Evaluator();
		string output = "";
		string expected;
		hilfe->write = lambda(string l) {output += l;};
		foreach (indices(obj), string n) hilfe->variables[n] = obj[n];
		foreach (pgm[name]/"\n", string line)
		{
			if (line == "") continue;
			if (!hilfe->state->finishedp())
			{
				//TODO: Deduplicate with the below
				hilfe->add_input_line(line);
				if (hilfe->state->finishedp()) expected = "";
			}
			else if (sscanf(line,"> %s", line))
			{
				if (compare(output, expected)) return 1;
				output = "";
				hilfe->add_input_line(line);
				if (hilfe->state->finishedp()) expected = "";
			}
			else if (expected) expected += line + "\n";
		}
		if (compare(output, expected)) return 1;
		++testspassed;
		write("pass\n");
	}
}

int main(int argc,array(string) argv)
{
	if (argc<2) exit(0,"USAGE: %s files_to_test.pike\n",argv[0]);
	run_tests(argv[1..][*]);
}
