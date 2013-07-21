####
# Copyright (c) 2013 Chris J Daly (github user cjdaly)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   cjdaly - initial API and implementation
####

module Napkin
  module ConversionUtil
    def parse_int(text)
      return nil if text.nil?
      begin
        return Integer(text)
      rescue ArgumentError => err
        return nil
      end
    end

    def parse_float(text)
      return nil if text.nil?
      begin
        return Float(text)
      rescue ArgumentError => err
        return nil
      end
    end
  end
end