import re
from pymarc import Record

re_isbn = re.compile(r'([^ ()]+[\dX])(?: \((?:v\. (\d+)(?: : )?)?(.*)\))?')
# handle ISBN like: 1402563884c$26.95
re_isbn_and_price = re.compile(r'^([-\d]+X?)c\$[\d.]+$')

class MarcException(Exception):
    # Base MARC exception class
    pass

class BadMARC(MarcException):
    pass

class NoTitle(MarcException):
    pass

class MarcBase(object):
    def read_isbn(self, f):
        found = []
        for k, v in f.get_subfields(['a', 'z']):
            m = re_isbn_and_price.match(v)
            if not m:
                m = re_isbn.match(v)
            if not m:
                continue
            found.append(m.group(1))
        return found

    def build_fields(self, want):
        self.fields = {}
        want = set(want)
        for tag, line in self.read_fields(want):
            self.fields.setdefault(tag, []).append(line)

    def get_fields(self, *tags):
        record = Record(data=self.data)
        return record.get_fields(*tags)
        #return [self.decode_field(i) for i in self.fields.get(tag, [])]
